//
//  Alertable.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/21/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit

protocol Alertable {}

extension Alertable where Self: UIViewController {
    func showAlert(_ message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}
