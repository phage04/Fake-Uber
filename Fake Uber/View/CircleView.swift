//
//  CircleView.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/18/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit

class CircleView: UIView {

    @IBInspectable var borderColor: UIColor?{
        didSet{
            setupView()
        }
    }
    
    override func awakeFromNib() {
        setupView()
    }

    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = borderColor?.cgColor
        self.layer.borderWidth = 1.5
    }
}
