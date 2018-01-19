//
//  UIViewExt.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/19/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit

extension UIView {
    func fadeTo(alpha: CGFloat, withDuration: TimeInterval) {
        UIView.animate(withDuration: withDuration) {
            self.alpha = alpha
        }
    }
}
