//
//  DriverAnnotation.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/20/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import Foundation
import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, withKey: String) {
        self.coordinate = coordinate
        self.key = withKey
        super.init()
    }
    
    func update(annotationPosition annotation: DriverAnnotation, withCoordinate coordinate: CLLocationCoordinate2D) {
        var location = self.coordinate
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        UIView.animate(withDuration: 1.0) {
            self.coordinate = location
        }
    }
}
