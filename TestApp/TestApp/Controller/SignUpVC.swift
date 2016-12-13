//
//  SignUpVC.swift
//  TestApp
//
//  Created by Nilesh on 12/12/16.
//  Copyright © 2016 Nilesh. All rights reserved.
//

import UIKit
import MBProgressHUD

class SignUpVC: UIViewController {
    
    @IBOutlet weak var txtLname: UITextField!
    @IBOutlet weak var txtFname: UITextField!
    @IBOutlet weak var txtPwd: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    
    var sendingDict : [String : String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "SignUp"
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func action_Button(_ sender: UIButton) {
        if self.isValidate() {
            self.callSignUpAPI(dict: sendingDict as NSDictionary)
        }
    }
    
    func isValidate()->Bool {
        
        let strEmailAddress = txtEmail.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let strpass = txtPwd.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let strFname = txtFname.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let strLname = txtLname.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
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
            sendingDict = ["email":strEmailAddress!,"password":strpass!,"first_name":strFname!,"last_name":strLname!]
        }
        
        
        return true
    }
    
    // MARK: - API Calling
    
    func callSignUpAPI (dict:NSDictionary) {
        
        if APIManagerSharedInstance.isNetworkConnected() {
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            APIManagerSharedInstance.callPostService(postdata: dict, token:"", type: "POST", urlString: APIs.SIGNUP as NSString ) { (result, error) in
                
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let errorvalue : String = result["error"] as! String
                    if (errorvalue == "0") {
                        
                        APIManagerSharedInstance.showAlert(message: result["message"] as! String)
                        _ = self.navigationController?.popViewController(animated: true)
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
