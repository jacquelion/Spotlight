//
//  InstaCollectionViewController.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/22/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class InstaCollectionViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    //MARK: - Collection View Outlets
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var mySpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var toolbar: UIToolbar!
    //Hold indexes of selected cells
    var selectedIndexes = [NSIndexPath]()
    //Track when cells are inserted, deleted, or updated
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var location: Location!
    
    //Set default map view
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var longitudeDelta: Double = 0.0
    var latitudeDelta: Double = 0.0
    
    //TODO: Add Sharing Capabilites via
    
    @IBAction func refreshPictures(sender: AnyObject) {
        mySpinner.hidden = false
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            for object in fetchedObjects{
                let image = object as! Image
                self.sharedContext.deleteObject(image)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        loadImages(self.location)
        
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch{}
        
        loadMapView()
        
        if let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first?.path {
            print("DOCUMENTS PATH: ", documentsPath) // "var/folder/.../documents\n" copy the full path
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        shareButton.enabled = false
        
        print("Location already loaded pictures? ", location.loadedPictures)
        if (location.loadedPictures == false) {
            refreshButton.enabled = false
            loadImages(location)
        }
    }
    
    //Layout the collection view
    //    override func viewDidLayoutSubviews() {
    //        super.viewDidLayoutSubviews()
    //
    //        // Lay out the collection view so that cells take up 1/3 of the width,
    //        // with no space in between.
    //        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    //        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    //        layout.minimumLineSpacing = 0
    //        layout.minimumInteritemSpacing = 0
    //
    //        let width = floor(self.myCollectionView.frame.size.width/2)
    //        layout.itemSize = CGSize(width: width, height: width)
    //        myCollectionView.collectionViewLayout = layout
    //    }
    
    
    func loadImages(location: Location){
        mySpinner.hidden = false
        if Reachability.isConnectedToNetwork() == false {
            mySpinner.hidden = true
            print("Internet connection FAILED")
            let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default) { _ in
                return
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true){}
            
        } else {
            
            InstagramClient.sharedInstance.getPicturesByLocation(self, location: location) { result, error in
                if let error = error {
                    print(error)
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                        self.refreshButton.enabled = true
                        self.mySpinner.hidden = true
                    }
                }
            }
        }
    }
    
    
    func loadMapView() {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let savedRegion = MKCoordinateRegion(center: center, span: span)
        print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
        mapView.setRegion(savedRegion, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
    }
    
    
    
    //MARK: - Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Image")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
    }()
    
    //MARK: - Collection View Functions
    let reuseIdentifier = "InstagramPictureCell"
    
    //MARK: - UICollectionViewDataSource Protocol
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        print("Number of ItemsInSection: ", sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.myCollectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! InstagramImageCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        shareButton.enabled = false
        //User can select and deselect on tap
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! InstagramImageCollectionViewCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            cell.layer.opacity = 1.0
            selectedIndexes.removeAtIndex(index)
        } else {
            cell.layer.opacity = 0.2
            selectedIndexes.append(indexPath)
        }
        
        if (selectedIndexes.count > 0) {
            shareButton.enabled = true
        } else {
            shareButton.enabled = false
        }
        
    }
    
    
    //MARK: - Fetched Results Controller Delegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        //start with empty arrays of each type:
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?){
        switch type{
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        myCollectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.myCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.myCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.myCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    func configureCell(cell: InstagramImageCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let image = fetchedResultsController.objectAtIndexPath(indexPath) as! Image
        
        if let imageView = image.imageView{
            image.loadUpdateHandler = nil
            cell.imageView.image = imageView
        } else {
            image.loadUpdateHandler = nil
            cell.imageView.image = UIImage(named: "imagePlaceholder")
            cell.cellSpinner.startAnimating()
            
            
            if let imageURL = NSURL(string: image.url) {
                InstagramClient.sharedInstance.taskForImage(imageURL) { data, error in
                    if let error = error {
                        print("error downloading photos from imageURL: \(imageURL) \(error.localizedDescription)")
                        dispatch_async(dispatch_get_main_queue()){
                            image.loadUpdateHandler = nil
                            cell.imageView.image = UIImage(named: "noImage")
                            cell.cellSpinner.stopAnimating()
                        }
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            if let imageFromData = UIImage(data: data!)
                            {
                                image.loadUpdateHandler = { [unowned self] () -> Void in
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.myCollectionView!.reloadItemsAtIndexPaths([indexPath])
                                        cell.cellSpinner.hidden = true
                                    })
                                }
                                image.imageView = imageFromData
                            }
                            else
                            {
                                image.loadUpdateHandler = nil
                                print("NO IMAGE.")
                                cell.imageView.image = UIImage(named: "noImage")
                                cell.cellSpinner.stopAnimating()
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    
}

extension InstaCollectionViewController : UIImagePickerControllerDelegate {
    
    func generateSelectedImage() -> UIImage {
        navigationController?.navigationBarHidden = true
        navigationController?.toolbarHidden = true
        
        tabBarController?.tabBar.hidden = true
        toolbar.hidden = true
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        print(self.view.frame)
        let selectedImage : UIImage =
            UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        navigationController?.navigationBarHidden = false
        tabBarController?.tabBar.hidden = false
        toolbar.hidden = false
        
        return selectedImage
    }
    
    @IBAction func shareImage(sender: AnyObject) {
        
        let myImages = generateSelectedImage()
        let vc = UIActivityViewController(activityItems: [myImages], applicationActivities: [])
        
        vc.completionWithItemsHandler = {
            activity, completed, items, error in
            if completed {
                self.navigationController!.popViewControllerAnimated(true)
            }
        }
        presentViewController(vc, animated: true, completion: nil)
    }
    
}