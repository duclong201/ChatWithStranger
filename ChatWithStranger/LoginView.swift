//
//  ContentView.swift
//  ChatWithStranger
//
//  Created by Long Nguyen on 5/5/2022.
//

import SwiftUI
import OSLog
import FirebaseStorage

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var logInStatusMessage = ""
    @State private var shouldShowImagePicker = false
    
    @State private var image: UIImage?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker Here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.gray, lineWidth: 3))

                        }
                    }

                    Group {
                        Group {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            SecureField("Password", text: $password)
                        }
                        .padding(12)
                        .background(.white)
                        
                        Button {
                            handleAction()
                        } label: {
                            HStack {
                                Spacer()
                                Text(isLoginMode ? "Log In" : "Create Account")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                            }.background(Color.blue)
                        }
                    }.cornerRadius(6)
                    
                    Text(logInStatusMessage)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker) {
            ImagePicker(image: $image)
        }
    }

    private func handleAction() {
        if isLoginMode {
            logIn()
        } else {
            createNewAccount()
        }
    }

    private func createNewAccount() {
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, err in
            if let err = err {
                os_log("Failed to create new user %@", err.localizedDescription)
                self.logInStatusMessage = "Failed to create user: \(err)"
                return
            }
            self.logInStatusMessage = "Successfully sign up"
            persistImageToStorage()
        }
    }
    
    private func logIn() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                self.logInStatusMessage = "Failed to create user: \(err)"
                return
            }
            self.logInStatusMessage = "Successfully log in"
            self.didCompleteLoginProcess()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {
            return
        }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(imageData, metadata: metadata) { metadata, err in
            if let err = err {
                self.logInStatusMessage = "Failed to push image to storage \(err)"
            }

            ref.downloadURL { url, err in
                if let err = err {
                    self.logInStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    return
                }
                guard let url = url else { return }
                storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return
        }

        let userData = ["email": self.email, "imageProfileUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) {
            err in
            if let err = err {
                self.logInStatusMessage = "Failed to update user into \(err)"
                return
            }
            self.didCompleteLoginProcess()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
//            MainMessageView()
        })
//        MainMessageView()
    }
}
