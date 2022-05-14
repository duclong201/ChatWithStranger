//
//  MainMessageView.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 7/5/2022.
//

import SwiftUI
import OSLog
import SDWebImageSwiftUI
import Firebase

class MainMessagesViewModel: ObservableObject {

    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    
    private var firestoreListener: ListenerRegistration?

    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchRecentMessages()
    }

    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find user id"
            return
        }
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, err in
            if let err = err {
                os_log("Failed to fetch user %@", err.localizedDescription)
                return
            }
            do {
                self.chatUser = try snapshot?.data(as: ChatUser.self)
            } catch {
                self.errorMessage = "Failed to decode user data"
            }
        }
    }
    
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }
        self.firestoreListener?.remove()
        self.recentMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessage)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch recent messages \(error)"
                return
            }
            
            querySnapshot?.documentChanges.forEach({ change in
                do {
                    let recentMessage = try change.document.data(as: RecentMessage.self)
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == change.document.documentID
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    self.recentMessages.insert(recentMessage, at: 0)
                } catch {
                    self.errorMessage = "Failed to decode document"
                }
            })
        }
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessageView: View {
    
    @State var shouldShowLogOutOptions = false
    @State var shouldShowNewMessageScreen = false
    @State var chatUser: ChatUser?
    @State var shouldNavigateToChatLogView = false

    @ObservedObject private var vm = MainMessagesViewModel()
    
    private var chatLogViewModel = ChatLogViewModel(chatUser: nil)

    private var customNavBar: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? "")).resizable()
                .frame(width: 70, height: 70)
                .cornerRadius(70)
                .clipped()
                .overlay(RoundedRectangle(cornerRadius: 70).stroke(Color.gray, lineWidth: 2))
    
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.chatUser?.username ?? "Unknown")")
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
        .padding(.horizontal)
        .padding(.vertical, 8)
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
                self.vm.fetchRecentMessages()
            })
        }
    }
    
    private var messageView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { message in
                VStack {
                    Button {
//                        ChatLogView(chatUser: <#T##ChatUser?#>)
                        Text("Destination")
//                        shouldNavigateToChatLogView.toggle()
                        let uid = FirebaseManager.shared.auth.currentUser?.uid == message.fromId ? message.toId : message.fromId
                        
                        self.chatUser = .init(id: uid, email: message.text, profileImageUrl: message.profileImageUrl)
                        self.chatLogViewModel.chatUser = self.chatUser
                        self.chatLogViewModel.fetchMessages()
                        self.shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: message.profileImageUrl))
                                .resizable()
                                .frame(width: 50, height: 50)
                                .cornerRadius(50)
                                .clipped()
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.gray, lineWidth: 2))
                                .shadow(radius: 5)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(message.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                Text(message.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.lightGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Text(message.timeAgo)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    Divider()
                    .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }

    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
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
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user in
                shouldNavigateToChatLogView.toggle()
                self.chatUser = user
                self.chatLogViewModel.chatUser = user
                self.chatLogViewModel.fetchMessages()
            })
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messageView
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: self.chatLogViewModel)
                }
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
