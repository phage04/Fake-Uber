//
//  RoundMapView.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/21/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit
import MapKit

class RoundMapView: MKMapView {
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
        self.clipsToBounds = true
    }

}
