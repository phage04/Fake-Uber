//
//  PickUpVC.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/21/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit
import MapKit
import Firebase
class PickUpVC: UIViewController {
    
    @IBOutlet weak var pickUpMapView: RoundMapView!
    
    var pickUpCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    
    var regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    var locationPlacemark: MKPlacemark!
    
    var currentUserId = FIRAuth.auth()?.currentUser?.uid
    override func viewDidLoad() {
        super.viewDidLoad()
        pickUpMapView.delegate = self
        locationPlacemark = MKPlacemark(coordinate: pickUpCoordinate)
        dropPinFor(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
        
        DataService.instance.REF_TRIPS.child(passengerKey).observe(.value, with: { (tripSnapshot) in
            if tripSnapshot.exists() {
                if tripSnapshot.childSnapshot(forPath: TRIP_IS_ACCEPTED).value as? Bool == true{
                    self.dismiss(animated: true, completion: nil)
                }
            }else{
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String) {
        self.pickUpCoordinate = coordinate
        self.passengerKey = passengerKey
    }

    @IBAction func acceptTripPressed(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, forDriverKey: currentUserId!)
        presentingViewController?.shouldPresentLoadingView(true)
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        UpdateService.instance.cancelTrip(withPassengerKey: passengerKey, forDriverKey: currentUserId!)
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
        
        annotationView?.image = UIImage(named: ANNO_DESTINATION)
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
