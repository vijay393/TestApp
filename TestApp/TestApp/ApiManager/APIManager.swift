//
//  APIManager.swift
//  TestApp
//
//  Created by Nilesh on 12/12/16.
//  Copyright © 2016 Nilesh. All rights reserved.
//

import UIKit
import SystemConfiguration

typealias StringConsumer = (_ result: NSDictionary, _ error: NSError?) -> Void

let APIManagerSharedInstance = APIManager()

struct Constants {
    static let alertTitle = "TestApp"
    static let serverError = "Oops! Something went wrong!\nPlease try again."
    static let noInternet = "Internet connection not found, Please make sure that you are connected with internet."
    static let userDefaultObj = UserDefaults.standard
    static let appObj = UIApplication.shared.delegate as! AppDelegate
    static let clientID = "yG6vFkxkwbNoAPfPZLQJdyv7OEWU0bnFssNvwBJ4"
    static let secret  = "V2yK8yweY9TpxbRHOqtHVJ565Dn7mNDxnQckNXdZACGMzLIXM1XkOIUwCQYRrNq0N7m3ammIG9q2b4CsWfWiOnO6FuBH418Qu3IFMH6yzRczMjmqMVhELY02huJ1AioB"
}

struct APIs {
    static let BASE_URL = "http://beta.cisin.com:3008/"
    static let LOGIN = "login/"
    static let SIGNUP = "sign_up/"
    static let GET_ALL_USER = "users/"
    static let CHANGE_PWD = "change-password/"
    static let TOKEN = "o/token/"
}


class APIManager: NSObject {
    
    class var sharedInstance: APIManager {
        return APIManagerSharedInstance
    }
    
    //MARK:- Validation Function
    
    func emailAddressValidation(emailAddress:String) -> Bool {
        
        let emailRegex = "(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}" +
            "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
            "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" +
            "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" +
            "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
            "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        let emailTest = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailTest.evaluate(with: emailAddress)
    }
    
    func showAlert(message:String) {
        DispatchQueue.main.async(execute: {
            UIAlertView(title: Constants.alertTitle, message: message, delegate: nil, cancelButtonTitle: "Ok").show()
        })
    }
    
    
    func isNetworkConnected() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    //MARK:- WebApis
    
    
    func callPostService(postdata:NSDictionary, token:NSString, type:NSString, urlString:NSString, consumer:@escaping StringConsumer) {
        let request : NSMutableURLRequest!
        
        if type == "POST" || type == "PUT" {
            request = self.doRequestWithURL(dictionary: postdata, url: urlString, type: type)
        }
        else if type == "GET" {
            request = self.doGetRequestWithURL(token: token , url: urlString)
        }
        else {
            request  = self.AuthRequest()
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) {
            (data, response, error) in
            // check for any errors
            
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error)
                
                let errorDict = ["error":"1","message":Constants.serverError] as [String : Any]
                consumer(errorDict as NSDictionary , nil)
                
                return
            }
            
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                
                let errorDict = ["error":"1","message":Constants.serverError] as [String : Any]
                consumer(errorDict as NSDictionary , nil)
                
                return
            }
            
            // parse the result as JSON, since that's what the API provides
            do {
                
                guard let todo:[String:AnyObject] = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject] else {
                    print("error trying to convert data to JSON")
                    
                    let errorDict = ["error":"1","message":Constants.serverError] as [String : Any]
                    consumer(errorDict as NSDictionary , nil)
                    return
                }
                
                consumer(todo as NSDictionary , nil)
                
            } catch  {
                let res: String = String(data: responseData, encoding: String.Encoding.utf8)!
                print(" Error Res Str \(res)")
                print("error trying to convert data to JSON")
                
                let errorDict = ["error":"1","message":Constants.serverError] as [String : Any]
                consumer(errorDict as NSDictionary , nil)
            }
        }
        task.resume()
    }
    
    
    func doRequestWithURL(dictionary:NSDictionary, url:NSString, type: NSString) -> NSMutableURLRequest {
        
        let request = NSMutableURLRequest()
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        request.timeoutInterval = 120
        request.httpMethod = type as String
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let theJSONData = try? JSONSerialization.data(
            withJSONObject: dictionary ,
            options: JSONSerialization.WritingOptions(rawValue: 0))
        
        let jsonString = NSString(data: theJSONData!,
                                  encoding: String.Encoding.ascii.rawValue)
        
        print("Request Object:\(dictionary)")
        print("Request string = \(jsonString!)")
        
        let postLength = NSString(format:"%lu", jsonString!.length) as String
        request.setValue(postLength, forHTTPHeaderField:"Content-Length")
        request.httpBody = jsonString!.data(using: String.Encoding.utf8.rawValue, allowLossyConversion:true)
        
        // set URL
        
        let completeURL = APIs.BASE_URL + (url as String)
        request.url = NSURL.init(string: completeURL as String) as URL?
        
        return request
        
    }
    
    func AuthRequest () -> NSMutableURLRequest {

        let authString = Constants.clientID + ":" + Constants.secret
        let authData : Data = authString.data(using: String.Encoding.utf8)!
        let tempStr : String = authData.base64EncodedString(options: [])
        let credentials = "Basic " + tempStr
        
        let headers = [
            "content-type": "application/x-www-form-urlencoded",
            "authorization": credentials,
            "cache-control": "no-cache",
            ]
        
        let username = "&username=" + (Constants.userDefaultObj.value(forKey: "Username") as! String)
        let password = "&password=" + (Constants.userDefaultObj.value(forKey: "Password") as! String)
        
        
        let postData = NSMutableData(data: "grant_type=password".data(using: String.Encoding.utf8)!)
        postData.append(username.data(using: String.Encoding.utf8)!)
        postData.append(password.data(using: String.Encoding.utf8)!)
        
        let strURL = APIs.BASE_URL + APIs.TOKEN
        
        let request = NSMutableURLRequest(url: NSURL(string: strURL)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 60.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data
        
        return request
    }
    
    func doGetRequestWithURL(token:NSString, url:NSString) -> NSMutableURLRequest {
        
        let headers = [
            "authorization": token as String,
            ]
        
        let strURL = APIs.BASE_URL + (url as String)
        
        let request = NSMutableURLRequest(url: NSURL(string: strURL)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 60.0)
        
        request.allHTTPHeaderFields = headers
        
        return request
    }
}
