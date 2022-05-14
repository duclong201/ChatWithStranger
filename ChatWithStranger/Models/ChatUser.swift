//
//  ChatUser.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 10/5/2022.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatUser: Identifiable, Codable {
    @DocumentID var id: String?
    let email, profileImageUrl: String
    
    var username: String {
        return email.components(separatedBy: "@").first ?? email
    }
}
