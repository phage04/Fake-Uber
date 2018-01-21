//
//  PassengerAnnotation.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/20/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, key: String) {
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
}
