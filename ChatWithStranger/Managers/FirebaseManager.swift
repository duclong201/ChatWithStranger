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
import FirebaseFunctions

class FirebaseManager: NSObject {
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    let functions: Functions

    static let shared = FirebaseManager()

    override init() {
        FirebaseApp.configure()

        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        self.functions = Functions.functions()

        super.init()
    }
}
