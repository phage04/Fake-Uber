//
//  ViewController.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/18/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import UIKit
import MapKit
import RevealingSplashView
import Firebase
import CoreLocation

enum AnnotationType {
    case pickup
    case destination
    case driver
}

enum ButtonAction {
    case requestRide
    case getDirectionsToPassenger
    case getDirectionsToDestination
    case startTrip
    case endTrip
}

class HomeVC: UIViewController, Alertable{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var centerMapBtn: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var delegate: CenterVCDelegate?
    var manager: CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    
    var currentUserId = FIRAuth.auth()?.currentUser?.uid
    
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    var tableView = UITableView()
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var route: MKRoute?
    var selectedItemPlacemark: MKPlacemark? = nil
    
    var actionForButton: ButtonAction = .requestRide
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        
        checkLocationAuthStatus()
        mapView.delegate = self
        destinationTextField.delegate = self
        
        centerMapOnUserLocation()
        
        DataService.instance.REF_DRIVERS.observe(.value, with: { (snapshot) in
            self.loadDriverAnnotationsFromFB()
            
            DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                }
            })
        })
        
        cancelBtn.alpha = 0.0
        
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()        
        
        
        UpdateService.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict {
                let pickUpCoordinateArray = tripDict[USER_PICKUP_COORDINATE] as! NSArray
                let tripKey = tripDict[USER_PASSENGER_KEY] as! String
                let acceptanceStatus = tripDict[TRIP_IS_ACCEPTED] as! Bool
               
                if acceptanceStatus == false {
                    DataService.instance.driverIsAvailable(key: self.currentUserId!, handler: { (available) in
                        if let available = available {
                            if available == true {
                                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                let pickUpVC = storyboard.instantiateViewController(withIdentifier: "PickUpVC") as? PickUpVC
                                pickUpVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickUpCoordinateArray[0] as! CLLocationDegrees, longitude: pickUpCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                                self.present(pickUpVC!, animated: true, completion: nil)
                            }
                        }
                    })
                }
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if currentUserId != nil {
            DataService.instance.userIsDriver(userKey: currentUserId!, handler: { (status) in
                if status == true {
                    self.buttonsForDriver(areHidden: true)
                }
            })
        }
        
        DataService.instance.REF_TRIPS.observe(.childRemoved, with: { (removedTripSnapshot) in
            let removedTripDict = removedTripSnapshot.value as? [String: AnyObject]
            if removedTripDict?[DRIVER_KEY] != nil {
                DataService.instance.REF_DRIVERS.child(removedTripDict?[DRIVER_KEY] as! String).updateChildValues([DRIVER_IS_ON_TRIP: false])
            }
            
            DataService.instance.userIsDriver(userKey: self.currentUserId!, handler: { (isDriver) in
                if isDriver == true {
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                } else {
                    self.cancelBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
                    self.actionBtn.animateBtn(shouldLoad: false, withMsg: MSG_REQUEST_RIDE)
                    
                    self.destinationTextField.isUserInteractionEnabled = true
                    self.destinationTextField.text = ""
                    
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                    self.centerMapOnUserLocation()
                }
            })
        })
        
        if currentUserId != nil {
            DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if let tripSnapshot = tripSnapshot.children.allObjects as? [FIRDataSnapshot] {
                            for trip in tripSnapshot {
                                if trip.childSnapshot(forPath: DRIVER_KEY).value as? String == self.currentUserId! {
                                    let pickupCoordinatesArray = trip.childSnapshot(forPath: USER_PICKUP_COORDINATE).value as! NSArray
                                    let pickupCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: pickupCoordinatesArray[0] as! CLLocationDegrees, longitude: pickupCoordinatesArray[1] as! CLLocationDegrees)
                                    let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                                    
                                    self.dropPinFor(placemark: pickupPlacemark)
                                    self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                                    
                                    self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: pickupCoordinate)
                                    
                                    self.actionForButton = .getDirectionsToPassenger
                                    self.actionBtn.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                                    
                                    self.buttonsForDriver(areHidden: false)
                                }
                            }
                        }
                    })
                }
            })
            connectUserAndDriverForTrip()
        }
        
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            manager?.startUpdatingLocation()
        } else{
            manager?.requestAlwaysAuthorization()
        }
    }
    
    func buttonsForDriver(areHidden: Bool) {
        if areHidden {
            self.actionBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
            self.cancelBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
            self.centerMapBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
            self.actionBtn.isHidden = true
            self.cancelBtn.isHidden = true
            self.centerMapBtn.isHidden = true
        } else {
            self.actionBtn.fadeTo(alpha: 1.0, withDuration: 0.2)
            self.cancelBtn.fadeTo(alpha: 1.0, withDuration: 0.2)
            self.centerMapBtn.fadeTo(alpha: 1.0, withDuration: 0.2)
            self.actionBtn.isHidden = false
            self.cancelBtn.isHidden = false
            self.centerMapBtn.isHidden = false
        }
    }
    
    func loadDriverAnnotationsFromFB(){
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [FIRDataSnapshot]{
                for driver in driverSnapshot{
                    if driver.hasChild(USER_IS_DRIVER){
                        if driver.hasChild(COORDINATE) {
                            if driver.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as? Bool == true{
                                if let driverDict = driver.value as? Dictionary<String, AnyObject>{
                                    let coordinateArray = driverDict[COORDINATE] as! NSArray
                                    let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                    
                                    let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                    
                                    var driverIsVisible: Bool {
                                        return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                            if let driverAnnotation = annotation as? DriverAnnotation {
                                                if driverAnnotation.key == driver.key {
                                                    driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                                    return true
                                                }
                                            }
                                            return false
                                            
                                        })
                                    }
                                    if !driverIsVisible {
                                        self.mapView.addAnnotation(annotation)
                                    }
                                }
                            }else{
                                for annotation in self.mapView.annotations {
                                    if annotation.isKind(of: DriverAnnotation.self) {
                                        if let annotation = annotation as? DriverAnnotation {
                                            if annotation.key == driver.key{
                                                self.mapView.removeAnnotation(annotation)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        })
        revealingSplashView.heartAttack = true
    }
    
    func connectUserAndDriverForTrip() {
        DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                
                DataService.instance.REF_TRIPS.child(tripKey!).observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    let tripDict = tripSnapshot.value as? Dictionary<String, AnyObject>
                    let driverId = tripDict?[DRIVER_KEY] as! String
                    
                    let pickupCoordinateArray = tripDict?[USER_PICKUP_COORDINATE] as! NSArray
                    let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                    let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                    let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
                    
                    DataService.instance.REF_DRIVERS.child(driverId).child(COORDINATE).observeSingleEvent(of: .value, with: { (coordinateSnapshot) in
                        let coordinateSnapshot = coordinateSnapshot.value as! NSArray
                        let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateSnapshot[0] as! CLLocationDegrees, longitude: coordinateSnapshot[1] as! CLLocationDegrees)
                        let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                        let driverMapItem = MKMapItem(placemark: driverPlacemark)
                        
                        let passengerAnnotation = PassengerAnnotation(coordinate: pickupCoordinate, key: self.currentUserId!)
                        self.mapView.addAnnotation(passengerAnnotation)
                        
                        self.searchMapKitForResultsWithPolyline(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                        self.actionBtn.animateBtn(shouldLoad: false, withMsg: MSG_DRIVER_COMING)
                        self.actionBtn.isUserInteractionEnabled = false
                    })
                    
                    DataService.instance.REF_TRIPS.child(tripKey!).observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if tripDict?[TRIP_IN_PROGRESS] as? Bool == true {
                            self.removeOverlaysAndAnnotations(forDrivers: true, forPassengers: true)
                            
                            let destinationCoordinateArray = tripDict?[USER_DESTINATION_COORDINATE] as! NSArray
                            let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                            
                            self.dropPinFor(placemark: destinationPlacemark)
                            self.searchMapKitForResultsWithPolyline(forOriginMapItem: pickupMapItem, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                            
                            self.actionBtn.setTitle(MSG_ON_TRIP, for: .normal)
                        }
                    })
                    
                })
            }
        })
    }
    
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
            }
        }
        
        DataService.instance.passengerIsOnTrip(passengerKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: driverKey!)
            } else{
                UpdateService.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: nil)
            }
        }
        
        self.actionBtn.isUserInteractionEnabled = true
    }    

    @IBAction func actionBtnPressed(_ sender: Any) {
        buttonSelector(forAction: actionForButton)
    }
    @IBAction func menuBtnPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
        
    }
    @IBAction func centerBtnPressed(_ sender: Any) {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for user in userSnapshot {
                    if user.key == self.currentUserId! {
                        if user.hasChild(TRIP_COORDINATE) {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                            self.centerMapBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
                        }else{
                            self.centerMapOnUserLocation()
                            self.centerMapBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        })

       
    }
    
    func buttonSelector(forAction action: ButtonAction) {
        switch action {
        case .requestRide:
            if destinationTextField.text != "" {
                UpdateService.instance.updateTripsWithCoordinatesUponRequest()
                actionBtn.animateBtn(shouldLoad: true, withMsg: nil)
                cancelBtn.fadeTo(alpha: 1.0, withDuration: 0.2)
                
                self.view.endEditing(true)
                destinationTextField.isUserInteractionEnabled = false
            }
            
        case .getDirectionsToPassenger:
            DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.REF_TRIPS.child(tripKey!).observe(.value, with: { (tripSnapshot) in
                        let tripDict = tripSnapshot.value as? Dictionary<String, AnyObject>
                        let pickUpCoordinateArray = tripDict?[USER_PICKUP_COORDINATE] as! NSArray
                        let pickUpCoordinate = CLLocationCoordinate2D(latitude: pickUpCoordinateArray[0] as! CLLocationDegrees, longitude: pickUpCoordinateArray[1] as! CLLocationDegrees)
                        
                        let pickUpMapItem = MKMapItem(placemark: MKPlacemark(coordinate: pickUpCoordinate))
                        pickUpMapItem.name = "Passenger Pickup Point"
                        pickUpMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    })
                }
            })
        case .startTrip:
            DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: false)
                    
                    DataService.instance.REF_TRIPS.child(tripKey!).updateChildValues([TRIP_IN_PROGRESS: true])
                    
                    DataService.instance.REF_TRIPS.child(tripKey!).child(USER_DESTINATION_COORDINATE).observeSingleEvent(of: .value, with: { (coordinateSnapshot) in
                        let destinationCoordinateArray = coordinateSnapshot.value as! NSArray
                        let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                        self.dropPinFor(placemark: destinationPlacemark)
                        self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                        self.setCustomRegion(forAnnotationType: .destination, withCoordinate: destinationCoordinate)
                        
                        self.actionForButton = .getDirectionsToDestination
                        self.actionBtn.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                    })
                }
            })
        case .getDirectionsToDestination:
            print("get directions to destination")
        case .endTrip:
            print("end trip")
    
        }
    }
    
}

extension HomeVC: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthStatus()
        if status == .authorizedAlways{
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
}

extension HomeVC: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        
        DataService.instance.userIsDriver(userKey: currentUserId!) { (isDriver) in
            if isDriver == true {
                DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                    } else{
                        self.centerMapOnUserLocation()
                    }
                })
            } else {
                DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                    } else{
                        self.centerMapOnUserLocation()
                    }
                })
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifier = ACCOUNT_TYPE_DRIVER
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: ANNO_DRIVER)
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let indentifier = ACCOUNT_TYPE_PASSENGER
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: indentifier)
            view.image = UIImage(named: ANNO_PICKUP)
            return view
        } else if let annotation = annotation as? MKPointAnnotation {
            let identifier = REGION_DESTINATION
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else{
                annotationView?.annotation = annotation
            }
            
            annotationView?.image = UIImage(named: ANNO_DESTINATION)
            return annotationView
            
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBtn.fadeTo(alpha: 1.0, withDuration: 0.2)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: self.route!.polyline)
        lineRenderer.strokeColor = UIColor.black.withAlphaComponent(0.75)
        lineRenderer.lineWidth = 3
        
        shouldPresentLoadingView(false)
   
        return lineRenderer
    }
    
    func performSearch(){
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error != nil {
                self.showAlert(ERROR_MSG_UNEXPECTED_ERROR)
            } else if response?.mapItems.count == 0{
                self.showAlert(ERROR_MSG_NO_MATCHES_FOUND)
            } else{
                for mapItem in response!.mapItems{
                    self.matchingItems.append(mapItem as MKMapItem)
                }
                self.tableView.reloadData()
                self.shouldPresentLoadingView(false)
            }
        }
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        
        selectedItemPlacemark = placemark
     
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    
    }
    
    func searchMapKitForResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem) {
        let request = MKDirectionsRequest()
        
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }
        
        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                self.showAlert(ERROR_MSG_UNEXPECTED_ERROR)
                return
            }
            self.route = response.routes[0]
            
           
            self.mapView.add(self.route!.polyline)
            
            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldPresentLoadingView(false)
        }
    }
    
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordianate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver {
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.key == key {
                        topLeftCoordianate.longitude = fmin(topLeftCoordianate.longitude, annotation.coordinate.longitude)
                        topLeftCoordianate.latitude = fmax(topLeftCoordianate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    topLeftCoordianate.longitude = fmin(topLeftCoordianate.longitude, annotation.coordinate.longitude)
                    topLeftCoordianate.latitude = fmax(topLeftCoordianate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
       
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self){
            topLeftCoordianate.longitude = fmin(topLeftCoordianate.longitude, annotation.coordinate.longitude)
            topLeftCoordianate.latitude = fmax(topLeftCoordianate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordianate.latitude - (topLeftCoordianate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordianate.longitude + (bottomRightCoordinate.longitude - topLeftCoordianate.longitude ) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordianate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordianate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    func removeOverlaysAndAnnotations(forDrivers: Bool?, forPassengers: Bool?) {
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
            
            if forPassengers == true {
                if let annotation = annotation as? PassengerAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
            
            if forDrivers == true {
                if let annotation = annotation as? DriverAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in mapView.overlays {
            if overlay is MKPolyline {
                mapView.remove(overlay)
            }
        }
    }
    
    func setCustomRegion(forAnnotationType type: AnnotationType, withCoordinate coordinate: CLLocationCoordinate2D) {
        if type == .pickup {
            let pickupRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: REGION_PICKUP)
            manager?.startMonitoring(for: pickupRegion)
        } else if type == .destination {
            let destinationRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: REGION_DESTINATION)
            manager?.startMonitoring(for: destinationRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler: { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true {
                if region.identifier == REGION_PICKUP {
                    self.actionForButton = .startTrip
                    self.actionBtn.setTitle(MSG_START_TRIP, for: .normal)
                    print("driver entered pickup region")
                } else if region.identifier == REGION_DESTINATION {
                    self.cancelBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
                    self.cancelBtn.isHidden = true
                    self.actionBtn.setTitle(MSG_END_TRIP, for: .normal)
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler: { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true {
                if region.identifier == REGION_PICKUP {
                    self.actionBtn.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                    print("driver exited pickup region")
                } else if region.identifier == REGION_DESTINATION {
                    self.cancelBtn.fadeTo(alpha: 0.0, withDuration: 0.2)
                    self.cancelBtn.isHidden = true
                    self.actionBtn.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                }
            }
        })
    }
}

extension HomeVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == destinationTextField{
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 170)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
            
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.tag = 18
            tableView.rowHeight = 60
            
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            })
            
        }

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray
                })
            }
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        
        DataService.instance.REF_USERS.child(currentUserId!).child(TRIP_COORDINATE).removeValue()
        self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
        centerMapOnUserLocation()
        return true
    }
    
    func animateTableView(shouldShow: Bool) {
        if shouldShow{
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: 170, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
                
            })
        } else{
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
                
            }, completion: { (finished) in
                for subview in self.view.subviews{
                    if subview.tag == 18 {
                        subview.removeFromSuperview()
                    }
                }
            })
        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        shouldPresentLoadingView(true)
        
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: currentUserId!)
        mapView.addAnnotation(passengerAnnotation)
        
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        let selectedMapItem = matchingItems[indexPath.row]
        
        DataService.instance.REF_USERS.child(currentUserId!).updateChildValues([TRIP_COORDINATE: [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
        
        dropPinFor(placemark: selectedMapItem.placemark)
        searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)
        
        animateTableView(shouldShow: false)
        print("selected")
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}
