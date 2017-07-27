//
//  FirebaseManager.swift
//  Shalk
//
//  Created by Nick Lee on 2017/7/27.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import Foundation
import Firebase

class FirebaseManager {

    func logIn(withEmail email: String, withPassword pwd: String) {

        // MARK: Start to login Firebase

        Auth.auth().signIn(withEmail: email, password: pwd) { (_, error) in

            if error != nil {

                // TODO: Error handling
                print(error?.localizedDescription ?? "No error data")

            }

            // MARK: User Signed in successfully.

            AlertManager.shared.loginMessageAlertController(title: "Successfully",

                                                            message: "You have signed in successfully! Click OK to main page. ",

                                                            handle: { _ in

                                                                let shakeVC = UIStoryboard(name: "Main",

                                                                                           bundle: nil).instantiateViewController(withIdentifier: "ShakeVC")

                                                                AppDelegate.shared.window?.rootViewController = shakeVC

            })

        }

    }

    func signUp(withUser name: String, withEmail email: String, withPassword pwd: String) {

        Auth.auth().createUser(withEmail: email, password: pwd) { (user, error) in

            if error != nil {

                // TODO: Error handling
                print(error?.localizedDescription ?? "No error data")

            }

            guard let okUser = user else { return }

            let request = okUser.createProfileChangeRequest()
            request.displayName = name
            request.commitChanges(completion: { (error) in

                if error != nil {

                    // TODO: Error handling
                    print(error?.localizedDescription ?? "No error data")

                }

                self.logIn(withEmail: email, withPassword: pwd)

            })

        }

    }

}
