//
//  MainMessageView.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 7/5/2022.
//

import SwiftUI
import OSLog
import SDWebImageSwiftUI

struct ChatUser {
    let uid, email, profileImageUrl: String
}

class MainMessagesViewModel: ObservableObject {

    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false

    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
    }

    func fetchCurrentUser() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find user id"
            return
        }
        
        self.errorMessage = "\(uid)"
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, err in
            if let err = err {
                os_log("Failed to fetch user %@", err.localizedDescription)
                return
            }
            self.errorMessage = "No document"
            guard let data = snapshot?.data() else {
                self.errorMessage = "No data found"
                return
            }
            let email = data["email"] as? String ?? ""
            let profileImageUrl = data["profileImageUrl"] as? String ?? ""
            self.chatUser = ChatUser(uid: uid, email: email, profileImageUrl: profileImageUrl)
            self.errorMessage = "\(data)"
        }
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessageView: View {
    
    @State var shouldShowLogOutOptions = false
    @ObservedObject private var vm = MainMessagesViewModel()

    private var customNavBar: some View {
        HStack(spacing: 16) {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? "")).resizable()
                .frame(width: 50, height: 50)
                .cornerRadius(50)
                .clipped()
                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.black, lineWidth: 1))
    
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.chatUser?.email ?? "Unknown")")
                    .font(.system(size: 24, weight: .bold))
                HStack(spacing: 5) {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 10, height: 10)
                    Text("Status")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }

            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign out"), action: {
                    vm.handleSignOut()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    
    private var messageView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    HStack(spacing: 15) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color.black, lineWidth: 1))
                        
                        VStack(alignment: .leading) {
                            Text("Username")
                                .font(.system(size: 14, weight: .bold))
                            Text("Message sent")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.lightGray))
                        }
                        Spacer()
                        
                        Text("22d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    private var newMessageButton: some View {
        Button {
            
        } label: {
            HStack {
                Spacer()
                Text("+ New Message").font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messageView
            }.overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
}

struct MainMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessageView()
    }
}
