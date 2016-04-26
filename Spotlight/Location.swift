//
//  Location.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/24/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit
import CoreData

class Location : NSManagedObject {
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var loadedPictures: Bool
    @NSManaged var images: [Image]
 
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        longitude = dictionary[Keys.Longitude] as! Double
        latitude = dictionary[Keys.Latitude] as! Double
        loadedPictures = false
    }
    
}
