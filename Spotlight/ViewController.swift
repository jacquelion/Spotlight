//
//  ViewController.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/21/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager: CLLocationManager!
    var startLocation: CLLocation!
    var locationStatus : NSString = "Not Started"
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func findMeButtonPressed(sender: AnyObject) {
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        startLocation = nil
        
        mapView.delegate = self
        
        view.backgroundColor = UIColor.grayColor()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - CLLocationManagerDelegate
    // If failed
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        locationManager.stopUpdatingLocation()
        print(error)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestLocation = locations.last
        
        print("latestLocation: ", latestLocation)
        let coord = latestLocation
        print("COORD: ", coord)
        
        let latitude = coord!.coordinate.latitude
        let longitude = coord!.coordinate.latitude
        print("Latitude: ", latitude)
        print("Longitude", longitude)
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
        updateMapLocation(latestLocation!)
        
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status {
        case CLAuthorizationStatus.Restricted:
            locationStatus = "Restricted Access to Location"
        case CLAuthorizationStatus.Denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.NotDetermined:
            locationStatus = "Status not determined"
        default:
            locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        
    }
    
    func updateMapLocation(location: CLLocation){
        //Add Annotation to Map
        let latitude = Double(location.coordinate.latitude)
        let longitude = Double(location.coordinate.longitude)
        print("Longitude: ", longitude, ", Latitude: ", latitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }
}

