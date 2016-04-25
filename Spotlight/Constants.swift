//
//  Constants.swift
//  Spotlight
//
//  Created by Jacqueline Sloves on 4/23/16.
//  Copyright © 2016 Jacqueline Sloves. All rights reserved.
//

import Foundation

extension InstagramClient {
    struct Constants {
        
        static let ApiScheme = "https"
        static let ApiHost = "api.instagram.com"
        static let ApiPath = "/v1/"
        
        static let AuthorizationURL : String = "https://api.instagram.com/oauth/authorize/"
        
        static let ClientId = "60e0fe0b74e849ec83f81f18b781b88f"
        static let ClientSecret = "409f6f46839b4f8a8da12c7ca46dc8bf"
        static let WebsiteURL = "http://www.jacquelinesloves.com"
        static let RedirectURI = "https://www.instagram.com/"
        static let SupportEmail = "coderjac@gmail.com"
        static let UserId = "231432668"
        static let AccessToken = "231432668.60e0fe0.ad3d167b242c4ba1b58a7031c843dcae"
    }
    
    struct Methods {
        static let OAuth = "/oauth"
        static let Authorize = "/authorize/"
        static let AccessToken = "/access_token/"
        static let Search = "/media/search"
    }
    
    struct ParameterKeys {
        static let clientId = "client_id"
        static let redirectURI = "redirect_uri"
        static let responseType = "response_type"
        static let lat = "lat"
        static let long = "lng"
    }
    
    struct ParameterValues {
        static let code = "code"
        static let token = "token"
    }
    
    struct JSONResponseKeys {
        static let accessToken = "access_token"
    }
    
    
}
