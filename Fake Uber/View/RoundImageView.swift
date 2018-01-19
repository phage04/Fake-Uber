//
//  RoundImageView.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/18/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {

    override func awakeFromNib() {
        setupView()
    }
    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }

}
