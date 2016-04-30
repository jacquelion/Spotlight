//
//  InstagramImageCollectionViewCell.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/25/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import UIKit

class InstagramImageCollectionViewCell : UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    var imageName: String = ""
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }

}
