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

class InstaCollectionViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    //MARK: - Collection View Outlets
   
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var location: Location!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch{}
        
        if let documentsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first?.path {
            print("DOCUMENTS PATH: ", documentsPath) // "var/folder/.../documents\n" copy the full path
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (location.loadedPictures == false) {
            loadImages(location)
        }
    }
    
    func loadImages(location: Location){
        InstagramClient.sharedInstance.getPicturesByLocation(location) { result, error in
            if let error = error {
                print(error)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    //MARK: - Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Image")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"id", ascending: true)]
        //fetchRequest.predicate = NSPredicate(format: "location == %@", self.location)
        
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
        let cell = myCollectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! InstagramImageCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
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
            
            if let imageURL = NSURL(string: image.url) {
                InstagramClient.sharedInstance.taskForImage(imageURL) { data, error in
                    if let error = error {
                        print("error downloading photos from imageURL: \(imageURL) \(error.localizedDescription)")
                        dispatch_async(dispatch_get_main_queue()){
                            image.loadUpdateHandler = nil
                            print("NO IMAGE LINE 166")
                            //cell.imageView.image = UIImage(named: "pictureNoImage")
                            //cell.cellSpinner.stopAnimating()
                        }
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            if let imageFromData = UIImage(data: data!)
                            {
                                image.loadUpdateHandler = { [unowned self] () -> Void in
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.myCollectionView!.reloadItemsAtIndexPaths([indexPath])
                                        // cell.cellSpinner.hidden = true
                                    })
                                }
                                image.imageView = imageFromData
                            }
                            else
                            {
                                image.loadUpdateHandler = nil
                                print("NO IMAGE LINE 187")
                                //cell.imageView.image = UIImage(named: "pictureNoImage")
                                //cell.cellSpinner.stopAnimating()
                            }
                        }
                    }
                }
            }
        }
    
    }
    
    
}
