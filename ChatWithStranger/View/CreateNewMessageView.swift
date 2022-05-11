//
//  CreateNewMessageView.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 11/5/2022.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    init() {
        fetchAllUser()
    }
    
    private func fetchAllUser() {
        FirebaseManager.shared.firestore.collection("users").getDocuments { documentSnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch users \(error.localizedDescription)"
                return
            }
            documentSnapshot?.documents.forEach({ snapshot in
                let data = snapshot.data()
                let chatUser = ChatUser(data: data)
                if chatUser.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    self.users.append(chatUser)
                }
            })
        }
    }
}

struct CreateNewMessageView: View {
    
    @State var searchTerm = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = CreateNewMessageViewModel()
    let didSelectNewUser: (ChatUser) -> ()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(vm.users) { user in
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.gray, lineWidth: 1))
                            Text(user.email)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        Divider()
                            .padding(.vertical, 8)
                    }
                }.padding()
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewMessageView { user in
            print("User \(user)")
        }
    }
}
