//
//  ImageCache.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/24/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    //MARK: - Retreiving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        //Return nil if identifier is nil or empty
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
        //1. Check if image is in memory cache
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        //2. Check if image is in hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    //MARK: - Saving Images
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        //Keep image in memory (Image Cache)
        inMemoryCache.setObject(image!, forKey: path)
        //And store in documents directory
        let data = UIImagePNGRepresentation(image!)!
        data.writeToFile(path, atomically: true)
    }
    
    //MARK: - Delete Image
    func deleteImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)

        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch {
                print("Coudl not remove item at path: \(path)")
            }
        }
    }

    //MARK: - Helper
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        return fullURL.path!
    }
}
