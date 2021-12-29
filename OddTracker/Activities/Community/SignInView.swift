//
//  SignInView.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.12.21.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    enum SignInStatus {
        case unknown
        case authorized
        case failure(Error?)
    }

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var status = SignInStatus.unknown

    var body: some View {
        NavigationView {
            Group {
                switch status {
                    case .authorized:
                        Text("You're all set!")
                    case .failure(let error):
                        if let error = error {
                            Text("Sorry, there was an error: \(error.localizedDescription)")
                        } else {
                            Text("Sorry, there was an error.")
                        }
                    case .unknown:
                        VStack(alignment: .leading) {
                            ScrollView {
                                Text("""
                                In order to keep our community safe, we ask that you sign in before commenting on a project.

                                We don't track your personal information; your name is used only for display purposes.

                                Please note: we reserve the right to remove messages that are inappropriate or offensive.
                                """)
                            }

                            Spacer()

                            SignInWithAppleButton(onRequest: configureSignIn, onCompletion: completeSignIn)
                                .frame(height: 44)
                                .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                            // currently the SIWA button doen't properly adapt to the devices dark mode
                            // until this is fixed the above code will provide a nice look even in dark mode
                            // sadly this means the button won't change when the user switches modes while
                            // the button is visible. luckily that basically never happens

                            Button("Cancel", action: close)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                }
            }
            .padding()
            .navigationTitle("Please sign in")
        }
    }

    /// Closes the current view
    func close() {
        presentationMode.wrappedValue.dismiss()
    }

    /// Handles the configuration of a "Sign in with Apple" request
    /// - Parameter request: The "Sign in with Apple" request
    func configureSignIn(_ request: ASAuthorizationAppleIDRequest) {

    }

    /// Finishes a "Sign in with Apple" request
    /// - Parameter result: The result of the "Sign in with Apple" request
    func completeSignIn(_ result: Result<ASAuthorization, Error>) {

    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
