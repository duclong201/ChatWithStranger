//
//  ChatLogView.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 11/5/2022.
//

import SwiftUI

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    @State var chatText = ""

    var body: some View {
        ZStack {
            messagesView
            VStack {
                Spacer()
                chatBottomBar.background(.white)
            }
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var messagesView: some View {
        ScrollView {
            ForEach(0..<20) { num in
                HStack {
                    Spacer()
                    HStack {
                        Text("Fake message")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.blue)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
    }

    private var chatBottomBar: some View {
        HStack {
            Image(systemName: "photo.on.rectangle")
            TextField("New message", text: $chatText)
            // Update with TextEditor
            Button {
                
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
            ChatLogView(chatUser: .init(data: ["email": "test.9@longnguyen.com", "uid" : "vtHxODwR9KeJT2HmSKvKeVE9BoE3", "profileImageUrl" : "https://firebasestorage.googleapis.com:443/v0/b/chat-with-stranger-2b9e7.appspot.com/o/vtHxODwR9KeJT2HmSKvKeVE9BoE3?alt=media&token=d6b6463e-bede-4dfa-a706-6c4b94352c2f"]))
        }
    }
}
