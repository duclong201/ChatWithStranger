//
//  ChatLogView.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 11/5/2022.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let fromId, toId, text: String
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    
    var firestoreListener: ListenerRegistration?
    
    var chatUser: ChatUser?

    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }

    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }
        guard let toId = chatUser?.id else { return }
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener({ querySnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to listen to message. Error \(error.localizedDescription)"
                return
            }
            
            querySnapshot?.documentChanges.forEach({ change in
                if change.type == .added {
                    do {
                        let message = try change.document.data(as: ChatMessage.self)
                        self.chatMessages.append(message)
                    } catch {
                        self.errorMessage = "Failed to decode chat message"
                    }
                }
            })
        })
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.id else { return }
        let document = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages).document(fromId).collection(toId).document()
        let messageData = [FirebaseConstants.fromId: fromId,
                           FirebaseConstants.toId: toId,
                           FirebaseConstants.text: chatText,
                           FirebaseConstants.timestamp: Timestamp()] as [String : Any]
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Error \(error.localizedDescription)"
                return
            }
            self.persistRecentMessage()
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages).document(toId).collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save to recipient \(error.localizedDescription)"
                return
            }
        }
    }
    
    private func persistRecentMessage() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }
        guard let chatUser = self.chatUser, let toId = chatUser.id else { return }
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessage)
            .document(fromId)
            .collection(FirebaseConstants.messages)
            .document(toId)

        let data = [FirebaseConstants.timestamp: Timestamp(),
                    FirebaseConstants.text: chatText,
                    FirebaseConstants.fromId: fromId,
                    FirebaseConstants.toId: toId,
                    FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
                    FirebaseConstants.email: chatUser.email] as [String : Any]
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message to firebase: \(error)"
                return
            }
        }
        
        let recipientDocument = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessage)
            .document(toId)
            .collection(FirebaseConstants.messages)
            .document(fromId)

        recipientDocument.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message to firebase: \(error)"
                return
            }
        }
    }
}

struct ChatLogView: View {

    @ObservedObject var vm: ChatLogViewModel
    static let emptyScrollToString = "Empty"

    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
        }
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }

    private var messagesView: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    ForEach(vm.chatMessages) { chatMessage in
                        MessageView(message: chatMessage)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    HStack { Spacer() }
                        .id(Self.emptyScrollToString)
                        .onReceive(vm.$count) { _ in
                            withAnimation(.easeOut(duration: 0.5)) {
                                scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                            }
                        }
                }
            }
            .background(Color(.init(white: 0.95, alpha: 1)))
            .safeAreaInset(edge: .bottom) {
                chatBottomBar
                    .background(Color(.systemBackground))
            }
        }
    }

    private var chatBottomBar: some View {
        HStack {
            Image(systemName: "photo.on.rectangle")
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatLogView(vm: ChatLogViewModel(chatUser: nil))
        }
    }
}

private struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
            HStack {
                Spacer()
                HStack {
                    Text(message.text)
                        .foregroundColor(.white)
                }
                .padding()
                .background(.blue)
                .cornerRadius(8)
            }
        } else {
            HStack {
                HStack {
                    Text(message.text)
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                Spacer()
            }
        }
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}
