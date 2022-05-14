//
//  FirebaseManager.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 7/5/2022.
//

import Foundation
import Firebase
import FirebaseStorage
import FirebaseFirestore

class FirebaseManager: NSObject {
    let auth: Auth
    let storage: Storage
    let firestore: Firestore

    static let shared = FirebaseManager()

    override init() {
        FirebaseApp.configure()

        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()

        super.init()
    }
}

struct FirebaseConstants {
    static let uid = "uid"
    static let messages = "messages"
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let recentMessage = "recent_message"
    static let profileImageUrl = "profileImageUrl"
    static let email = "email"
}
