//
//  GCDBlackBox.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/23/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}