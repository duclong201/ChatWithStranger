//
//  ImageManager.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 7/5/2022.
//

import Foundation
import UIKit

enum ImageRepositoryError: Swift.Error {
    case notImplemented
    case notAnImage
    case cancelled
    case unableToReadData
    case unableToWriteData
    case unableToUploadImage
    case emptyURL

    var localizedDescription: String {
        switch self {
        case .notAnImage:
            return "Not an image"
        case .cancelled:
            return "Cancelled"
        case .unableToReadData:
            return "Unable to read data"
        case .unableToWriteData:
            return "Unable to write data"
        case .notImplemented:
            return "Not implemented"
        case .unableToUploadImage:
            return "Unable to upload image"
        case .emptyURL:
            return "URL is nil"
        }
    }
}

struct LoadImageResult {
    let url: URL?
    let image: UIImage?
    let error: ImageRepositoryError?

    init(url: URL?, image: UIImage?, error: ImageRepositoryError?) {
        self.url = url
        self.image = image
        self.error = error
    }
}

typealias LoadCallback = (_ image: UIImage?, _ url: URL?, _ error: Error?) -> Void

protocol ImageRepository: AnyObject {
    var textureURLs: [String] {get set}
    var cache: CacheManager {get set}
    // Where the URL is the local URL that the image was saved to
    typealias SaveCallback = (Result<(UIImage, URL), ImageRepositoryError>) -> Void

    typealias UploadCallback = (Result<URL, ImageRepositoryError>) -> Void

    func importImageDocument(from localURL: URL, completion: @escaping SaveCallback)
    func loadImage(from url: URL?, completion: @escaping LoadCallback)
    func updateTextures()
    func uploadImage(url: URL, completion: @escaping UploadCallback)
    func setPriorityForImageDownloadTask(for url: URL?, priority: Operation.QueuePriority)
    func cancelAllOperations()
}

class ImageManager: NSObject {
    private let fileManager = FileManager.default
    private let cache = Cache.shared
    
    lazy var imageDownloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.imageRepository.imageDownloadqueue"
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    func loadImage(from url: URL?, completion: @escaping LoadCallback) {
        
    }
}

class FileManagerImageRepository: ImageRepository {

    private let documentRoot: URL
    let fileManager = FileManager.default
    var cache = Cache.shared
    private var downloadCallback: LoadCallback?
    lazy var imageDownloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.imageRepository.imageDownloadqueue"
        queue.qualityOfService = .userInteractive
        return queue
    }()


    var textureURLs: [String] {
        didSet {
            UserDefaults.standard.textureURLs = textureURLs.sorted()
        }
    }

    init(documentRoot: URL) {
        self.documentRoot = documentRoot
        textureURLs = UserDefaults.standard.textureURLs ?? []
    }

    func loadImage(from url: URL?, completion: @escaping LoadCallback) {
        guard let url = url else {
            completion(nil, nil, ImageRepositoryError.emptyURL)
            return
        }

        if let data = self.cache[url.absoluteString] {
            if let cached = UIImage.loadViaCGImage(data: data) {
                completion(cached.correctOrientation(), url, nil)
            } else {
                completion(nil, url, ImageRepositoryError.unableToReadData)
            }
        } else {
            let allOperations = imageDownloadQueue.operations as? [LoadOperation]
            if let operations = allOperations?.filter({$0.imageUrl.absoluteString == url.absoluteString && $0.isFinished == false && $0.isExecuting == true }),
               let operation = operations.first {
                operation.queuePriority = .veryHigh
            } else {
                let operation = LoadOperation(url: url)
                operation.queuePriority = .high
                operation.downloadHandler = { (image, url, error) in
                    if let newImage = image, let url = url {
                        self.cache[url.absoluteString] = newImage.pngData()
                    }
                    completion(image, url, error)
                }
                imageDownloadQueue.addOperation(operation)
            }
        }
    }

    func importImageDocument(from localURL: URL, completion: @escaping ImageRepository.SaveCallback) {
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.loadImage(from: localURL) { image, _, _ in
                guard let image = image else {
                    completion(.failure(.unableToReadData))
                    return
                }
                strongSelf.copyImage(from: localURL) { result in
                    switch result {
                    case .success(let copiedURL):
                        strongSelf.cache[copiedURL.absoluteString] = image.pngData()!
                        completion(.success((image.correctOrientation(), copiedURL)))
                    case .failure:
                        completion(.failure(.unableToWriteData))
                    }
                }
            }
        }
    }

    private func copyImage(from localURL: URL, completion: (Result<URL, Error>) -> Void) {
        let pathExtension = localURL.pathExtension
        let name = UUID().uuidString
        let path = pathExtension.isEmpty ? name : "\(name).\(pathExtension)"
        let destinationURL = documentRoot.appendingPathComponent(path)
        do {
            try fileManager.copyItem(at: localURL, to: destinationURL)
            completion(.success(destinationURL))
        } catch {
            completion(.failure(error))
        }
    }

    func updateTextures() {
        let texturesRef = publicRef.child("textures/")
        var storageURLs: [String] = []
        let group = DispatchGroup()
        texturesRef.listAll { (list, _) in
            for item in list.items.sorted(by: {$0.name < $1.name}) {
                group.enter()
                item.downloadURL { (url, err) in
                    if let url = url, err == nil {
                        storageURLs.append(url.absoluteString)
                        if !self.textureURLs.contains(url.absoluteString) {
                            self.textureURLs.append(url.absoluteString)
                        }
                        if self.cache[url.absoluteString] == nil {
                            self.loadImage(from: url) { _, _, _  in
                            }
                        }
                    }
                    group.leave()
                }
            }
            group.notify(queue: .global()) {
                for url in self.textureURLs where !storageURLs.contains(url) {
                    self.cache[url] = nil
                    let index = self.textureURLs.firstIndex(of: url)!
                    self.textureURLs.remove(at: index)
                }
            }
        }
    }

    func uploadImage(url: URL, type: ImageType, completion: @escaping UploadCallback) {
        let userRepo = DependencyContainer.shared.userRepository
        let configRepo = DependencyContainer.shared.configRepository
        guard let userId = userRepo?.getUser()?.uid else { return }
        let currentPresetId = configRepo.current().id
        var org = ""
        if let orgId = userRepo?.currentOrg.id {
            if orgId != .empty {
                org = "organisations/\(orgId)"
            } else {
                org = "users"
            }
        }
        let imageRef = publicRef.child("\(org)/\(userId)/Presets/\(currentPresetId)/\(type.rawValue).png")
        loadImage(from: url) { image, _, error  in
            guard let image = image else {
                completion(.failure(.unableToReadData))
                if let error = error {
                    os_log("Failed to load image from url %@", log: log, error.localizedDescription as! CVarArg)
                }
                return
            }
            if let data = image.imageData {
                imageRef.putData(data, metadata: nil) { (_, error) in
                    imageRef.downloadURL { (url, error) in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                        guard let downloadURL = url else {
                            completion(.failure(.unableToUploadImage))
                            return
                        }
                        completion(.success(downloadURL))
                    }
                }
            } else {
                completion(.failure(.unableToUploadImage))
            }
        }
    }

    func setPriorityForImageDownloadTask(for url: URL?, priority: Operation.QueuePriority) {
        guard let url = url else {
            return
        }
        let allOperations = imageDownloadQueue.operations as? [LoadOperation]
        if let operations = allOperations?.filter({$0.imageUrl.absoluteString == url.absoluteString && $0.isFinished == false && $0.isExecuting == true }),
            let operation = operations.first {
            operation.queuePriority = priority
        }
    }

    func cancelAllOperations() {
        imageDownloadQueue.cancelAllOperations()
    }

}

class LoadOperation: Operation {
    var downloadHandler: LoadCallback?
    var imageUrl: URL!

    override var isAsynchronous: Bool {
        get {
            return true
        }
    }

    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }

    override var isExecuting: Bool {
        return _executing
    }

    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }

        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }

    override var isFinished: Bool {
        return _finished
    }

    func executing(_ executing: Bool) {
        _executing = executing
    }

    func finish(_ finished: Bool) {
        _finished = finished
    }

    required init (url: URL) {
        self.imageUrl = url
    }

    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        self.executing(true)
        self.loadImageFromUrl()
    }

    private func loadData(url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            if url.isFileURL {
                let lastPathComponent = url.lastPathComponent
                let localURL = URL.documentRoot!.appendingPathComponent(lastPathComponent)
                return try Data(contentsOf: localURL)
            } else {
                throw error
            }
        }
    }

    func downloadImageFromUrl(url: URL) {
        let newSession = URLSession.shared
        let downloadTask = newSession.downloadTask(with: url) { (location, _, error) in
            if let locationUrl = location, let data = try? Data(contentsOf: locationUrl) {
                let image = UIImage.loadViaCGImage(data: data)
                self.downloadHandler?(image, url, error)
            }
            self.finish(true)
            self.executing(false)
        }
        downloadTask.resume()
    }

    func loadImageFromLocalUrl(url: URL) {
        do {
            let data = try loadData(url: url)
            let image = UIImage.loadViaCGImage(data: data)
            self.downloadHandler?(image, url, nil)
        } catch {
            self.downloadHandler?(nil, url, ImageRepositoryError.unableToReadData)
        }
        self.finish(true)
        self.executing(false)
    }

    func loadImageFromUrl() {
        guard let url = self.imageUrl else {
            self.finish(true)
            self.executing(false)
            self.downloadHandler?(nil, self.imageUrl, ImageRepositoryError.emptyURL)
            return
        }
        if url.isFileURL {
            loadImageFromLocalUrl(url: url)
        } else {
            downloadImageFromUrl(url: url)
        }
    }
}
