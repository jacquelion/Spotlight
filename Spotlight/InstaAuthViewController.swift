//
//  InstaAuthViewController.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/22/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import Foundation
import UIKit

class InstaAuthViewController: UIViewController {

    var urlRequest: NSURLRequest? = nil //this is passed in when view controller is instantiated
    var accessToken: String! = nil
    var completionHandlerForView: ((success: Bool, errorString: String?) -> Void)? = nil
    //TODO: Pass Location

    //MARK: - Outlets
    
    @IBOutlet weak var webView: UIWebView!

    //MARK: - Life Cycle
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        webView.delegate = self
        
        navigationItem.title = "Instagram Auth"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(InstaAuthViewController.cancelAuth))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if let urlRequest = urlRequest {
            webView.loadRequest(urlRequest)
        }
    }
    
    //MARK: - Cancel Auth Flow
    
    func cancelAuth() {
        dismissViewControllerAnimated(true, completion: nil)
    }

}

//MARK: - InstgramAuthViewController: UIWebViewDelegate

extension InstaAuthViewController : UIWebViewDelegate {

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let url = request.URL
        var key: String
        var value: String
        if (url!.fragment != nil) {
            key = (url?.fragment?.componentsSeparatedByString("=").first)!
            value = (url?.fragment?.componentsSeparatedByString("=").last)!
            print("Key, value: ", key, value)
            if key == "access_token" {
                accessToken = value
                InstagramClient.sharedInstance.AccessToken = accessToken
                saveAccessToken(accessToken)
                print("ACCESS TOKEN: ", accessToken)
                //TODO: Make request with location
            }
            
        }
        
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let urlString = ("https://www.instagram.com#access_token=\(accessToken)")
        print("webView.request!.URL!.absoluteString: ", webView.request!.URL!.absoluteString)
        //TODO: Sub Redirect URI Constant for string
        if webView.request!.URL!.absoluteString == "https://www.instagram.com/" {
            dismissViewControllerAnimated(true) {
                self.completionHandlerForView!(success: true, errorString: nil)
            }
        }
    }
    
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("accessTokenArchive").path!
    }
    
    func saveAccessToken(accessToken: String){
        let dictionary = [
            "accessToken" : accessToken
        ]
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }

}