//
//  PickUpVC.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/21/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit
import MapKit
class PickUpVC: UIViewController {
    
    @IBOutlet weak var pickUpMapView: RoundMapView!
    
    var pickUpCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    
    var regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    var locationPlacemark: MKPlacemark!
    override func viewDidLoad() {
        super.viewDidLoad()
        pickUpMapView.delegate = self
        locationPlacemark = MKPlacemark(coordinate: pickUpCoordinate)
        dropPinFor(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)        
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String) {
        self.pickUpCoordinate = coordinate
        self.passengerKey = passengerKey
    }

    @IBAction func acceptTripPressed(_ sender: Any) {
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension PickUpVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let indentifier = "pickupPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: indentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: indentifier)
        } else{
           annotationView?.annotation = annotation
        }
        
        annotationView?.image = UIImage(named: "destinationAnnotation")
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation) {
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        pickUpMapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        
        pin = placemark
        
        for annotation in pickUpMapView.annotations{
            pickUpMapView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        
        pickUpMapView.addAnnotation(annotation)
    }
}
