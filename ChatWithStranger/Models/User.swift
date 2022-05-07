//
//  User.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 7/5/2022.
//

import Foundation

struct User: Codable, Equatable {
    let profile: UserProfile
}

struct UserProfile: Codable, Equatable {
    let name: String
    let email: String
    let imageProfileUrl: String
}

struct UserData: Codable, Equatable {
    let signIns: Int
}
