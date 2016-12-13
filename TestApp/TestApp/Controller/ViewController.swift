//
//  ViewController.swift
//  TestApp
//
//  Created by Nilesh on 12/12/16.
//  Copyright © 2016 Nilesh. All rights reserved.
//

import UIKit
import MBProgressHUD

class ViewController: UIViewController {
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPwd: UITextField!
    
    var sendingDict : [String : String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "SignIn"
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func action_Button(_ sender: UIButton) {
        
        switch sender.tag {
        case 100:
            
            if self.isValidate() {
                self.callLoginAPI(dict: sendingDict as NSDictionary)
            }
            break
        case 101:
            print("SignUp")
            break
        default:
            print("Default")
            break
        }
    }
    
    func isValidate()->Bool {
        
        let strEmailAddress = txtEmail.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let strpass = txtPwd.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if strEmailAddress?.characters.count == 0
        {
            APIManagerSharedInstance.showAlert(message: "Please fill email address field")
            return false;
        }
        else if (!APIManagerSharedInstance.emailAddressValidation(emailAddress: strEmailAddress!))
        {
            APIManagerSharedInstance .showAlert(message: "Please fill valid Email address")
            
            return false;
        }
        else if (strpass?.characters.count)! < 4
        {
            APIManagerSharedInstance .showAlert(message: "Please fill password fields(Password length minimum 4)")
            
            return false;
        }
        else{
            sendingDict = ["email":strEmailAddress!,"password":strpass!]
        }
        
        return true
    }
    
    // MARK: - API Calling
    
    func callLoginAPI (dict:NSDictionary) {
        
        if APIManagerSharedInstance.isNetworkConnected() {
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            APIManagerSharedInstance.callPostService(postdata: dict, token:"", type: "POST", urlString: APIs.LOGIN as NSString ) { (result, error) in
                
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let errorvalue : String = result["error"] as! String
                    if (errorvalue == "0") {
                        
                        Constants.userDefaultObj.setValue(self.txtPwd.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), forKey: "Password")
                        Constants.userDefaultObj.setValue(self.txtEmail.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), forKey: "Username")
                        Constants.userDefaultObj.synchronize()
                        let vc = self.storyboard!.instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    else {
                        if result["message"] is NSArray {
                            let arr : NSArray = result["message"] as! NSArray
                            let strMsg = arr.componentsJoined(by: ",")
                            APIManagerSharedInstance.showAlert(message: strMsg)
                        }
                        else {
                            APIManagerSharedInstance.showAlert(message: result["message"] as! String)
                        }
                    }
                }
            }
        }
        else {
            APIManagerSharedInstance.showAlert(message: Constants.noInternet)
        }
    }
    
}

