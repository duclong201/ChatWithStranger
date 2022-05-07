//
//  MainMessageView.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 7/5/2022.
//

import SwiftUI
import OSLog

struct ChatUser {
    let uid, name, email, profileImageUrl: String
}

class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""

    init() {
        fetchCurrentUser()
    }

    private func fetchCurrentUser() {
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
            self.errorMessage = "\(data)"
        }
    }
}

struct MainMessageView: View {
    
    @State var shouldShowLogOutOptions = false
    @ObservedObject private var vm = MainMessagesViewModel()

    private var customNavBar: some View {
        HStack(spacing: 16) {

            Image(systemName: "person.fill")
                .font(.system(size: 34, weight: .heavy))
    
            VStack(alignment: .leading, spacing: 4) {
                Text("User name")
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
                    print("Handle sign out")
                }),
                .cancel()])
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
                Text("Current user id \(vm.errorMessage)")
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
