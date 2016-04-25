//
//  InstagramConvenience.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/23/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import Foundation
import UIKit

extension InstagramClient {
    
    //Refer to the docs for further instruction: https://www.instagram.com/developer/authentication/
    //Step 1: Direct User to Authorization URL
    //Step 2: Receive the redirect from Instagram
    //Step 3: Request the Access Token
    
    func authenticateWithViewController(hostViewController: UIViewController, completionHandlerForAuth: (success: Bool, errorString: String?) -> Void) {
        
        getToken(hostViewController) { (success, errorString) in
            
            if success {
                
                self.getPicturesByLocation(hostViewController) { (success, errorString) in
                    if (success) {
                        //save access token
                    } else {
                        completionHandlerForAuth(success: success, errorString: errorString)
                    }
                }
            } else {
                completionHandlerForAuth(success: success, errorString: errorString)
            }
        }
    }
    
    private func getToken(hostViewController: UIViewController, completionHandlerForCode: (success: Bool, errorString: String?) -> Void) {
        let webAuthViewController = hostViewController.storyboard!.instantiateViewControllerWithIdentifier("InstaAuthViewController") as! InstaAuthViewController
        
        let urlString = "https://api.instagram.com/oauth/authorize/?client_id=60e0fe0b74e849ec83f81f18b781b88f&redirect_uri=https://www.instagram.com/&response_type=token&scope=public_content"
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        
        webAuthViewController.urlRequest = request
        webAuthViewController.completionHandlerForView = completionHandlerForCode
        
        let webAuthNavigationController = UINavigationController()
        webAuthNavigationController.pushViewController(webAuthViewController, animated: false)
        
        performUIUpdatesOnMain {
            hostViewController.presentViewController(webAuthNavigationController, animated: true, completion: nil)
        }
        
        
    }
    
    func getPicturesByLocation(hostViewController: UIViewController, completionHandlerForLogin:(success: Bool, errorString: String?) -> Void) {
        
        var parameters = [String: AnyObject]()
        parameters["access_token"] = InstagramClient.sharedInstance().AccessToken
        parameters["count"] = 5
        
        taskForGETMethod("users/self/media/recent/", parameters: parameters) { (results, error) in
            if let error = error {
                print(error)
                //completionHandlerForAuth(success: false, errorString: "Could not get pictures by location.")
            } else {
                print("RESULTS: ", results)
                if let data = results["data"] as? [[String: AnyObject]] {
                    print("DATA: ", data)
//                    if let imageObjects = data["images"] as? [String:AnyObject] {
//                            print("imageDictionaries: ", imageObjects)
//                       }
//                    } else {
//                        print("Could not find images in \(data)")
//                   }
                    //completionHandlerForAuth(success: true, errorString: nil)
                } else {
                    print("Could not find data in \(results)")
                    //completionHandlerForUserID(success: false, userID: nil, errorString: "Login Failed (User ID).")
                }
            }
        }
        
    }
    
}