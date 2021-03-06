//
//  LoginVC.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/19/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController, UITextFieldDelegate, Alertable {

    @IBOutlet weak var emailField: RoundedCornerTextField!
    @IBOutlet weak var passwordField: RoundedCornerTextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var authBtn: RoundedShadowButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
        

        view.bindToKeyboard()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
    }
    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func authBtnPressed(_ sender: Any) {
        
        if emailField.text != nil && passwordField.text != nil {
            authBtn.animateBtn(shouldLoad: true, withMsg: nil)
            self.view.endEditing(true)
            
            if let email = emailField.text, let password = passwordField.text {
                FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                    if error == nil{
                        if let user = user {
                            if self.segmentedControl.selectedSegmentIndex == 0 {
                                let userData = ["provider": user.providerID] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                            } else{
                                let userData = ["provider": user.providerID, USER_IS_DRIVER: true, ACCOUNT_PICKUP_MODE_ENABLED: false, DRIVER_IS_ON_TRIP: false] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                            }
                        }
                        print("Email user authenticated successfully in Firebase")
                        self.dismiss(animated: true, completion: nil)
                    }else{
                        
                        if let errorCode = FIRAuthErrorCode(rawValue: error!._code) {
                            switch errorCode {
                            case .errorCodeEmailAlreadyInUse:
                                self.showAlert(ERROR_MSG_EMAIL_ALREADY_IN_USE)
                            case .errorCodeWrongPassword:
                                self.showAlert(ERROR_MSG_WRONG_PASSWORD)
                            case .errorCodeUserNotFound:
                        
                                FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                                    if error != nil {
                                        if let errorCode = FIRAuthErrorCode(rawValue: error!._code) {
                                            switch errorCode {
                                            case .errorCodeInvalidEmail:
                                                self.showAlert(ERROR_MSG_INVALID_EMAIL)
                                            case .errorCodeEmailAlreadyInUse:
                                                self.showAlert(ERROR_MSG_EMAIL_ALREADY_IN_USE)
                                            default:
                                                self.showAlert(ERROR_MSG_UNEXPECTED_ERROR)
                                            }
                                        }
                                    }else{
                                        if let user = user {
                                            if self.segmentedControl.selectedSegmentIndex == 0 {
                                                let userData = ["provider": user.providerID] as [String: Any]
                                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                                            } else{
                                                let userData = ["provider": user.providerID, USER_IS_DRIVER: true, ACCOUNT_PICKUP_MODE_ENABLED: false, DRIVER_IS_ON_TRIP: false] as [String: Any]
                                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                                            }
                                        }
                                        print("Successfully created a new user in firebase.")
                                    }
                                    self.dismiss(animated: true, completion: nil)
                                })
                            default:
                                self.showAlert(ERROR_MSG_UNEXPECTED_ERROR)
                            }
                            
                        }
                        
                        
                    }
                })
            }
        }
    }
    

}
