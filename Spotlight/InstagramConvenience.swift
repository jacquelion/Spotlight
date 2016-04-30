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
                completionHandlerForAuth(success: success, errorString: errorString)
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
    
    func getPicturesByLocation(location: Location, completionHandlerForLogin:(success: Bool, errorString: String?) -> Void) {
        
        var parameters = [String: AnyObject]()
        parameters["access_token"] = InstagramClient.sharedInstance.AccessToken
        //parameters["count"] = 5
        parameters[InstagramClient.ParameterKeys.lat] = location.latitude
        parameters[InstagramClient.ParameterKeys.long] = location.longitude
        parameters["distance"] = 5000
        
        taskForGETMethod(InstagramClient.Methods.Search, parameters: parameters) { (results, error) in
        //taskForGETMethod("users/self/media/recent/", parameters: parameters) { (results, error) in
            if let error = error {
                print(error)
                completionHandlerForLogin(success: false, errorString: "Could not get pictures by location.")
            } else {
                //print("RESULTS: ", results)
                guard let data = results["data"] as? [[String: AnyObject]] else {
                    print("ERROR WITH DATA: ", results["data"])
                    return
                }
                print("DATA: ", data)
                
                if (data.isEmpty) {
                    //alert user that there search returned no results.
                    let alertController = UIAlertController(title: "No Results", message: "There are no pictures at the specified location. Please try a query at a different location.", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style:UIAlertActionStyle.Default, handler: nil))
                    
                    //hostViewController.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    var count = 0
                    for dataDictionary in data {
                        guard let dataObject = data[count] as? [String: AnyObject] else {
                            print("ERROR WITH DATA[COUNT]:", data[count])
                            return
                        }
                        print("DATA[COUNT]: ", data[count])
                        
                        guard let images = dataObject["images"] as? [String:AnyObject] else {
                            print("ERROR WITH IMAGES", dataObject["images"])
                            return
                        }
                        print("IMAGES: ", dataObject["images"])
                        
                        guard let lowResImage = images["low_resolution"] as? [String: AnyObject] else {
                            print("ERROR WITH LOWRES", images["low_resolution"])
                            return
                        }
                        print("LOW RES IMAGE: ", images["low_resolution"])
                        
                        guard let imageURL = lowResImage["url"] as? String else {
                            print("ERROR WITH IMAGEURL", lowResImage["url"])
                            return
                        }
                        
                        print("IMAGEURL: ", lowResImage["url"])
                        self.imageURLArray.append(imageURL)

                        count += 1
                    }
                    print("IMAGE URL ARRAY: ", self.imageURLArray)
                    
                    let images = Image.imagesFromImageURLArray(self.imageURLArray, location: location)
                    
                    InstagramClient.sharedInstance.images = images
                    
                    completionHandlerForLogin(success: true, errorString: nil)
                    
                                        
                }
            }
        }
    }
    
    func taskForImage(imageURL: NSURL, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
        
        let request = NSURLRequest(URL: imageURL)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Download Error: ", error)
                let newError = InstagramClient.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
}
    