//
//  MapViewController.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/21/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var startLocation: CLLocation!
    var locationStatus : NSString = "Not Started"
    var locations = [Location]()
    var location : String = ""
    var longitude : Double = 0.0
    var latitude : Double = 0.0
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mySpinner: UIActivityIndicatorView!
    
    
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
        searchTextField.delegate = self
        
        view.backgroundColor = UIColor.grayColor()
        
        //enable long press to drop a pin
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(_:)))
        uilgr.minimumPressDuration = 0.8
        mapView.addGestureRecognizer(uilgr)
        
        mySpinner.startAnimating()
        view.alpha = 0.5
        
        
        // Do any additional setup after loading the view, typically from a nib.
        loadMapAnnotations()
        restoreAccessToken()
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveMapRegion()
    }
    
    func loadMapAnnotations(){
        locations = fetchAllLocations()
        
        for i in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: i.latitude, longitude: i.longitude)
            mapView.addAnnotation(annotation)
        }
    }
    
    func fetchAllLocations() -> [Location] {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        do {
            print("Fetch Request: \(fetchRequest)")
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Location]
        } catch let error as NSError {
            print("Error in fetchAllLocations(): \(error)")
            return [Location]()
        }
    }
    
    //MARK: - Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // MARK: - Save the zoom level helpers
    
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    var accessTokenFilePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("accessTokenArchive").path!
    }
    
    
    func restoreAccessToken() {
        if let accessTokenDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(accessTokenFilePath) as? [String: AnyObject] {
            let accessToken = accessTokenDictionary["accessToken"] as! String
            InstagramClient.sharedInstance.AccessToken = accessToken
        }
    }
    
    //MARK: - CLLocationManagerDelegate
    // If failed
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        locationManager.stopUpdatingLocation()
        print(error)
        if Reachability.isConnectedToNetwork() == false {
            mySpinner.hidden = true
            print("Internet connection FAILED")
            let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default) { _ in
                return
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true){}
            
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestLocation = locations.count - 1
        let newLocation = locations[latestLocation]
        
        print("latestLocation: ", latestLocation)
        let coord = newLocation
        
        let latitude = coord.coordinate.latitude
        let longitude = coord.coordinate.longitude
        
        if startLocation == nil {
            startLocation = newLocation
        }
        
        updateMapLocation(newLocation)
        locationManager.stopUpdatingLocation()
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
        
        var region: MKCoordinateRegion = self.mapView.region
        region.center.latitude = latitude
        region.center.longitude = longitude
        
        region.span = MKCoordinateSpanMake(0.5, 0.5)
        
        //Establish center point of map view to placemark
        self.mapView.setRegion(region, animated: true)
        //self.mapView.addAnnotation(MKPlacemark(placemark: placemark))
        
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
        print("Added Annotation: ", annotation)
        
        var dictionary = [String : AnyObject]()
        
        dictionary[Location.Keys.Latitude] = latitude
        dictionary[Location.Keys.Longitude] = longitude
        
        let locationToBeAdded = Location(dictionary: dictionary, context: sharedContext)
        
        self.locations.append(locationToBeAdded)
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    //MARK: -Drop A Pin Functions
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        switch gestureRecognizer.state {
        case .Began:
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            latitude = Double(newCoordinates.latitude)
            longitude = Double(newCoordinates.longitude)
            print("Longitude: ", longitude, ", Latitude: ", latitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
        case .Ended:
            
            //CORE DATA
            var dictionary = [String : AnyObject]()
            
            dictionary[Location.Keys.Latitude] = latitude
            dictionary[Location.Keys.Longitude] = longitude
            
            let locationToBeAdded = Location(dictionary: dictionary, context: sharedContext)
            
            self.locations.append(locationToBeAdded)
            
            var region: MKCoordinateRegion = self.mapView.region
            region.center.latitude = latitude
            region.center.longitude = longitude
            region.span = MKCoordinateSpanMake(0.5, 0.5)
            
            //Establish center point of map view to placemark
            self.mapView.setRegion(region, animated: true)
            
            CoreDataStackManager.sharedInstance().saveContext()
        default:
            break
        }
    }
}


//MARK: - MapView Delegate

extension MapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        let latitude = (view.annotation?.coordinate.latitude)!
        let longitude = (view.annotation?.coordinate.longitude)!
        
        if (InstagramClient.sharedInstance.AccessToken != nil) {
            segueToCollectionView(latitude, longitude: longitude)
        } else {
            InstagramClient.sharedInstance.authenticateWithViewController(self) { (success, errorString) in
                performUIUpdatesOnMain{
                    if success {
                        print("SUCCESS on Access Token!")
                        self.segueToCollectionView(latitude, longitude: longitude)
                    } else {
                        print("ERROR on Access Token: ", errorString)
                    }
                }
            }
        }
    }
    
    func segueToCollectionView(latitude: Double, longitude: Double){
        let storyboard = UIStoryboard.init(name: "Main", bundle: NSBundle.mainBundle())
        let vc = storyboard.instantiateViewControllerWithIdentifier("InstaCollectionViewController") as! InstaCollectionViewController
        vc.latitude = latitude
        vc.longitude = longitude
        vc.latitudeDelta = self.mapView.region.span.latitudeDelta
        vc.longitudeDelta = self.mapView.region.span.longitudeDelta
        
        for location in self.locations {
            if location.latitude == latitude && location.longitude == longitude {
                vc.location = location
                break
            }
        }
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mySpinner.hidden = true
        mySpinner.stopAnimating()
        view.alpha = 1.0
    }
    
}

extension MapViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func findLocation(sender: AnyObject) {
        if (searchTextField.text == "") {
            let alert = UIAlertController(title: "Empty Fields", message: "Please enter a valid address.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default) { _ in
                //stop login if there are empty fields
                return
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true){}
        } else {
            location = searchTextField.text!
            geocodeLocation()
        }
        
    }
    
    func geocodeLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location, completionHandler: {(placemarks, error) -> Void in
            if((error) != nil){
                print("Error", error)
                self.mySpinner.hidden = true
                let alert = UIAlertController(title: "Geocoder Failed", message: "Please enter a city and state, (i.e. Cupertino, CA).", preferredStyle: .Alert)
                let action = UIAlertAction(title: "OK", style: .Default) { _ in
                    self.dismissViewControllerAnimated(true, completion: nil)
                    return
                }
                alert.addAction(action)
                self.presentViewController(alert, animated: true){}
                
            } else {
                guard let placemark = placemarks![0] as? CLPlacemark else {
                    let alert = UIAlertController(title: "Geocoder Failed", message: "Please enter a city and state, (i.e. Cupertino, CA).", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "OK", style: .Default) { _ in
                        self.dismissViewControllerAnimated(true, completion: nil)
                        return
                    }
                    alert.addAction(action)
                    self.presentViewController(alert, animated: true){}
                }
                
                let locationToBeAdded = placemark.location
                self.updateMapLocation(locationToBeAdded!)
                
//                var region: MKCoordinateRegion = self.mapView.region
//                region.center.latitude = (placemark.location?.coordinate.latitude)!
//                region.center.longitude = (placemark.location?.coordinate.longitude)!
//                
//                region.span = MKCoordinateSpanMake(0.5, 0.5)
//                
//                //Establish center point of map view to placemark
//                self.mapView.setRegion(region, animated: true)
//                self.mapView.addAnnotation(MKPlacemark(placemark: placemark))
//                
//                //get Longitude/Latitude coordinates from placemark location
//                self.longitude = (placemark.location?.coordinate.longitude)!
//                self.latitude = (placemark.location?.coordinate.latitude)!
                
                self.mySpinner.hidden = true
            }
        })
    }
    
}
