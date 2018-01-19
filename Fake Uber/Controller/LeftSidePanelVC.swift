//
//  LeftSidePanelVC.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/18/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit
import Firebase

class LeftSidePanelVC: UIViewController {
    
    let appDelegate = AppDelegate.getAppDelegate()

    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userAccountTypeLabel: UILabel!
    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var pickUpMode: UILabel!
    @IBOutlet weak var logInOutBtn: UIButton!
    @IBOutlet weak var pickUpSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

      
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickUpSwitch.isOn = false
        pickUpSwitch.isHidden = true
        pickUpMode.isHidden = true
        
        if FIRAuth.auth()?.currentUser == nil {
            userEmailLabel.text = ""
            userAccountTypeLabel.text = ""
            userImageView.isHidden = true
            logInOutBtn.setTitle("Sign Up /Login", for: .normal)
        }else{
            userImageView.isHidden = false
            userEmailLabel.text = FIRAuth.auth()?.currentUser?.email
            userAccountTypeLabel.text = ""
            logInOutBtn.setTitle("Logout", for: .normal)
        }
        
        observePassengersAndDrivers()
    }
    
    func observePassengersAndDrivers() {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    if snap.key == FIRAuth.auth()?.currentUser?.uid {
                        self.userAccountTypeLabel.text = "PASSENGER"
                        self.pickUpSwitch.isHidden = true
                        self.pickUpMode.isHidden = true
                    }
                }
            }
        })
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    if snap.key == FIRAuth.auth()?.currentUser?.uid {
                        self.userAccountTypeLabel.text = "DRIVER"
                        self.pickUpSwitch.isHidden = false
                        self.pickUpMode.isHidden = false
                        
                        
                        let switchStatus = snap.childSnapshot(forPath: "isPickUpModeEnabled").value as! Bool
                        self.pickUpSwitch.isOn = switchStatus
                        if self.pickUpSwitch.isOn == true {
                            self.pickUpMode.text = "PICKUP MODE ENABLED"
                        }else{
                            self.pickUpMode.text = "PICKUP MODE DISABLED"
                        }
                        
                    }
                }
            }
        })
        
    }
    
    @IBAction func signUpLoginBtnPressed(_ sender: Any) {

        if FIRAuth.auth()?.currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
        }else{
            do{
                try FIRAuth.auth()?.signOut()
                userEmailLabel.text = ""
                userAccountTypeLabel.text = ""
                pickUpMode.text = ""
                userImageView.isHidden = true
                pickUpSwitch.isHidden = true
                pickUpMode.isHidden = true
                logInOutBtn.setTitle("Sign Up /Login", for: .normal)
            }catch (let error) {
                print(error)
            }
        }
    }
    
    @IBAction func pickUpSwitchToggled(_ sender: Any) {
        if self.pickUpSwitch.isOn == true {
            self.pickUpMode.text = "PICKUP MODE ENABLED"
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child((FIRAuth.auth()?.currentUser?.uid)!).updateChildValues(["isPickUpModeEnabled": true])
        }else{
            self.pickUpMode.text = "PICKUP MODE DISABLED"
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child((FIRAuth.auth()?.currentUser?.uid)!).updateChildValues(["isPickUpModeEnabled": false])
        }
    }
}
