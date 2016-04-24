//
//  InstagramClient.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/23/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import Foundation

//var requestString = "https://api.instagram.com/v1/media/search?lat=48.858844&lng=2.294351&access_token=\(accessToken)"
//var requestURL = NSURL(string: requestString)
//var request = NSURLRequest(URL: requestURL!)
//webView.loadRequest(NSURLRequest)

//MARK: - InstagramClient : NSObject

class InstagramClient : NSObject {
    
    var session = NSURLSession.sharedSession()
    
    var AccessToken: String? = nil
    
    //MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: Shared Instance
    class func sharedInstance() -> InstagramClient {
        struct Singleton {
            static var sharedInstance = InstagramClient()
        }
        return Singleton.sharedInstance
    }
    
    //MARK: GET
    func taskForGETMethod(method: String, var parameters: [String: AnyObject], completionHandlerForGET: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //Set Parameters
        //parameters[ParameterKeys.clientId] = Constants.ClientId
        //parameters[ParameterKeys.redirectURI] = Constants.RedirectURI
        //parameters[ParameterKeys.responseType] = ParameterValues.code
        
        var url = instagramURLFromParameters(parameters, withPathExtension: method)
        print("Line 42, REQUEST URL: ", url)
        
        var urlString = "https://api.instagram.com/v1/users/self/media/recent/?access_token=\(Constants.AccessToken)"
        //"https://api.instagram.com/v1/users/self/?access_token=231432668.60e0fe0.ad3d167b242c4ba1b58a7031c843dcae"
        //"https://api.instagram.com/v1/media/search?lat=48.858844&lng=2.294351&access_token=231432668.60e0fe0.ad3d167b242c4ba1b58a7031c843dcae&scope=public_content"
        
        var urlRequest = NSURL(string: urlString)
        
        //Build URL, Configure request
        let request = NSMutableURLRequest(URL: urlRequest!)
        print("REQUEST: ", request)
        //Make the Request
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            print("Data: ", data)
            print("Response: ", response)
            print("Error: ", error)
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                print("STATUS CODE: ", (response as? NSHTTPURLResponse)?.statusCode)
                return
            }

            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
        
    }
    
    //MARK: POST
    
    func taskForPostMethod(method: String, var parameters: [String: AnyObject], jsonBody: String, completionHandlerForPOST: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        //Set Parameters
        //Build URL, Configure Request
        //var url = instagramURLFromParameters(parameters, withPathExtension: method)
        var urlString = "https://api.instagram.com/oauth/access_token"
        print("Line 90 REQUEST URL: ", urlString)
        var url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = jsonBody.dataUsingEncoding(NSUTF8StringEncoding)
        print("Line 95 REQUEST: ", request)
        //Make Request
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForPOST(result: nil, error: NSError(domain: "taskForPOSTMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                let statusCodeResponse = (response as? NSHTTPURLResponse)?.statusCode
                print("STATUS CODE: ", statusCodeResponse)
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForPOST)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
        
    }
    
    
    //MARK: Helpers
    
    //given RAW JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
    
    //create a URL from parameters
    private func instagramURLFromParameters(parameters: [String: AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = InstagramClient.Constants.ApiScheme
        components.host = InstagramClient.Constants.ApiHost
        components.path = InstagramClient.Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
}