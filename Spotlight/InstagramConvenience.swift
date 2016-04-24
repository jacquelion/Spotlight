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
                //save code to variable accessible throughout app
                //self.code = code
                
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
        
        let urlString = "https://api.instagram.com/oauth/authorize/?client_id=60e0fe0b74e849ec83f81f18b781b88f&redirect_uri=https://www.instagram.com/&response_type=token&scope=basic"
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
        //https://api.instagram.com/v1/media/search?lat=48.858844&lng=2.294351&access_token=ACCESS-TOKEN

        var parameters = [String: AnyObject]()
        //parameters["lat"] = Double(37.87144)
        //parameters["lng"] = Double(122.27275)
        //parameters["scope"] = "public_content"
        //parameters["count"] = 20
        parameters["access_token"] = InstagramClient.sharedInstance().AccessToken
        //https://api.instagram.com/v1/users/self/media/liked?access_token=ACCESS-TOKEN
//Method for search by lat/long: /media/search
        
        taskForGETMethod("/users/self/", parameters: parameters) { (results, error) in
            if let error = error {
                print(error)
                //completionHandlerForAuth(success: false, errorString: "Could not get pictures by location.")
            } else {
                print("RESULTS: ", results)
                if let data = results["data"] as? NSArray {
                    print("DATA: ", data)
                    //completionHandlerForAuth(success: true, errorString: nil)
                } else {
                    print("Could not find data in \(results)")
                    //completionHandlerForUserID(success: false, userID: nil, errorString: "Login Failed (User ID).")
                }
            }
        }
        
    }
    
}