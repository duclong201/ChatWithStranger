////
////  Cache.swift
////  ChatWithStranger
////
////  Created by Long Nguyen on 7/5/2022.
////
//
//import Foundation
//import OSLog
//
//public protocol CacheManager {
//    var primaryCache: CacheProvider { get set }
//    var secondaryCache: CacheProvider? { get set }
//    subscript(key: String) -> Data? { get set }
//    func clearCache()
//}
//
//public protocol CacheProvider {
//    func load(key: String) -> Data?
//    func save(key: String, value: NSData?)
//    func clearCache()
//}
//
//public class Cache: CacheManager {
//    public static let shared: CacheManager = Cache()
//    public var primaryCache: CacheProvider = MemoryCache()
//    public var secondaryCache: CacheProvider? = FileCache(cacheDir: "Permanent Cache")
//    public subscript(key: String) -> Data? {
//        get {
//            guard let result = primaryCache.load(key: key) else {
//                if let file = secondaryCache?.load(key: key) {
//                    primaryCache.save(key: key, value: file as NSData?)
//                    return file
//                }
//                return nil
//            }
//            return result
//        }
//        set {
//            let data: NSData? = newValue as NSData?
//            primaryCache.save(key: key, value: data)
//            secondaryCache?.save(key: key, value: data)
//        }
//    }
//    public func clearCache() {
//        primaryCache.clearCache()
//        secondaryCache?.clearCache()
//    }
//}
//
//public class MemoryCache: CacheProvider {
//    private let cache: NSCache<NSString, NSData> = NSCache<NSString, NSData>()
//    public func load(key: String) -> Data? {
//        return cache.object(forKey: NSString(string: key)) as Data?
//    }
//    public func save(key: String, value: NSData?) {
//        if let new = value {
//            self.cache.setObject(new, forKey: NSString(string: key))
//        } else {
//            self.cache.removeObject(forKey: NSString(string: key))
//        }
//    }
//    public func clearCache() {
//        cache.removeAllObjects()
//    }
//}
//
//public class FileCache: CacheProvider {
//    fileprivate var loggingEnabled: Bool
//    private let cacheDirectory: String
//    init(cacheDir: String, enableLogging: Bool = true) {
//        cacheDirectory = cacheDir
//        loggingEnabled = enableLogging
//    }
//    public func load(key: String) -> Data? {
//        guard let path = fileURL(fileName: key) else {
//            return nil
//        }
//        var data: Data?
//        do {
//            data = try Data(contentsOf: path)
//        } catch {
//            os_log("Couldn't create data object: %@", log: log, type: .error, error.localizedDescription)
//        }
//        return data
//    }
//    public func save(key: String, value: NSData?) {
//        guard let path = fileURL(fileName: key) else {
//            return
//        }
//        if let new = value as Data? {
//            do {
//                os_log("Save to path %@", path as CVarArg)
//                try new.write(to: path, options: .atomic)
//            } catch {
//                os_log("Error writing data to the file: ", log: log, type: .error, error.localizedDescription)
//            }
//        } else {
//            try? FileManager.default.removeItem(at: path)
//            os_log("Remove item at path %@", path as CVarArg)
//        }
//    }
//    public func clearCache() {
//        deleteCacheDirectory()
//    }
//    private func fileURL(fileName name: String) -> URL? {
//        guard let escapedName = name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
//            return nil
//        }
//        var cachesDir: URL?
//        do {
//            cachesDir = try cachesDirectory()
//        } catch {
//            os_log("Error getting caches directory: ", log: log, type: .error, error.localizedDescription)
//            return nil
//        }
//        return cachesDir?.appendingPathComponent(escapedName)
//    }
//    private func cachesDirectory() throws -> URL? {
//        var cachesDir: URL?
//        do {
//            cachesDir = try FileManager
//                .default
//                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//                .appendingPathComponent(cacheDirectory, isDirectory: true)
//        } catch {
//            throw error
//        }
//        guard let dir = cachesDir else {
//            return nil
//        }
//        do {
//            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
//        } catch {
//            throw error
//        }
//        return dir
//    }
//    private func deleteCacheDirectory() {
//        var cachesDir: URL?
//        do {
//            cachesDir = try cachesDirectory()
//        } catch {
//            os_log("Error getting caches directory: ", log: log, type: .error, error.localizedDescription)
//            return
//        }
//        guard let dir = cachesDir else {
//            return
//        }
//        do {
//            try FileManager.default.removeItem(at: dir)
//        } catch {
//            os_log("Error deleting files from the caches directory: ", log: log, type: .error, error.localizedDescription)
//        }
//    }
//}
