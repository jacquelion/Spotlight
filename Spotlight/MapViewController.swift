//
//  MapViewController.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/21/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
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
    
    //MARK: - MapView Delegate
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        let coordinate = view.annotation?.coordinate
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let vc = storyboard.instantiateViewControllerWithIdentifier("InstaAuthViewController") as! InstaAuthViewController
        
        let urlString = "https://api.instagram.com/oauth/authorize/?client_id=60e0fe0b74e849ec83f81f18b781b88f&redirect_uri=https://www.instagram.com/&response_type=token"
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        vc.urlRequest = request
        
        //vc.latitude = (view.annotation?.coordinate.latitude)!
        //vc.longitude = (view.annotation?.coordinate.longitude)!
        //vc.latitudeDelta = self.mapView.region.span.latitudeDelta
        //vc.longitudeDelta = self.mapView.region.span.longitudeDelta
        
//        for location in locations {
//            if location.latitude == (coordinate!.latitude) && location.longitude == (coordinate!.longitude) {
//                vc.location = location
//                break
//            }
//        }
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
}
