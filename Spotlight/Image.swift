//
//  Image.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/24/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import CoreData

class Image : NSManagedObject {
    
    struct Keys {
        static let id = "id"
        static let url = "url"
        static let imagePath = "path"
        static let Location = "location"
    }
    
    @NSManaged var id: NSNumber
    @NSManaged var url: String
    @NSManaged var path: String?
    @NSManaged var location: Location?
    
    var loadUpdateHandler: (() -> Void)?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    override func prepareForDeletion() {
        imageView = nil
        if let path = path {
            if (NSFileManager.defaultManager().fileExistsAtPath(path)) {
                do {
                    //delete from Cache
                    InstagramClient.Caches.imageCache.deleteImage(imageView, withIdentifier: path)
                } catch {
                    NSLog("Could not delete photo at \(path): \(error)")
                }
            }
        }
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        //CORE DATA
        let entity = NSEntityDescription.entityForName("Image", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        id = dictionary[Keys.id] as! NSNumber
        url = dictionary[Keys.url] as! String
        path = dictionary[Keys.imagePath] as? String
        location = dictionary[Keys.Location] as? Location
    }
    
    static func imagesFromImageURLArray(imageURLs: [String], location: Location) -> NSSet {
        var images = NSSet()
        var maxImages = 20 //Set as Constant: Constants.Instagram.MaxImages
        let originalResultCount = imageURLs.count
        var countResults = 0
        var startCount = 0
        
        //Randomizes start point:
        if (originalResultCount < maxImages) {
            maxImages = originalResultCount
        } else {
            startCount = Int(arc4random_uniform(UInt32(originalResultCount - maxImages)))
        }
        
        for url in imageURLs {
            if(countResults < (maxImages + startCount) && countResults >= startCount) {
                if let imageURL = NSURL(string: imageURLs[countResults] ) {
                    let imagePath = "/\(imageURL.lastPathComponent!)" ?? ""
                    let filteredResult: [String : AnyObject] = [Keys.url : url, Keys.imagePath: imagePath, Keys.Location: location, Keys.id: countResults]
    
                    dispatch_async(dispatch_get_main_queue()) {
                        images = images.setByAddingObject(Image(dictionary: filteredResult, context: CoreDataStackManager.sharedInstance().managedObjectContext))
                    }
                } else {
                    print("Could not convert photo url to NSURL from photo results.")
                }
            }
            countResults += 1
        }
        print("IMAGES: ", images)

        return images
    }
    
    var imageView: UIImage? {
        get {
            //TODO: return image from Cache with path identifier
            return InstagramClient.Caches.imageCache.imageWithIdentifier(path)
        }
        
        set {
            //TODO: store image in Cache with path identifier'
            InstagramClient.Caches.imageCache.storeImage(newValue, withIdentifier: path!)
            loadUpdateHandler?()
        }
    }
}
