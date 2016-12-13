//
//  ChangePwd.swift
//  TestApp
//
//  Created by Nilesh on 12/12/16.
//  Copyright © 2016 Nilesh. All rights reserved.
//

import UIKit
import MBProgressHUD

class ChangePwd: UIViewController {
    
    @IBOutlet weak var txtOldPwd: UITextField!
    @IBOutlet weak var txtNewPwd: UITextField!
    @IBOutlet weak var txtConfirmPwd: UITextField!
    
    var tokenStr : String!
    var sendingDict = [String:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.callToGetTokenAPI()
        self.title = "Change Password"
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action
    
    func isValidate()->Bool {
        
        let strOldpass = txtOldPwd.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let strNewpass = txtNewPwd.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let strConfirmpass = txtConfirmPwd.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if((strOldpass!.characters.count) < 4)
        {
            APIManagerSharedInstance .showAlert(message: "Please fill old password field(Password length minimum 4)")
            return false;
        }
        else if((strNewpass!.characters.count) < 4)
        {
            APIManagerSharedInstance .showAlert(message: "Please fill new password field(Password length minimum 4)")
            return false;
        }
        else if((strConfirmpass!.characters.count) < 4)
        {
            APIManagerSharedInstance .showAlert(message: "Please fill confirm password field(Password length minimum 4)")
            return false;
        }
        else if( strNewpass != strConfirmpass)
        {
            APIManagerSharedInstance .showAlert(message: "New password & confirm password must be same.")
            return false;
        }
        else if( strNewpass == strOldpass)
        {
            APIManagerSharedInstance .showAlert(message: "New password must different from old password.")
            return false;
        }
        
        sendingDict = ["token":self.tokenStr,"old_password":strOldpass!,"newpassword":strNewpass!,"confirm_password":strConfirmpass!]
        
        return true
        
    }
    
    @IBAction func action_Button (_ sender: AnyObject) {
        if self.isValidate() {
            self.callUpdatePasswordAPI(dict: sendingDict as NSDictionary)
        }
        
        
    }
    
    // MARK: - API Calling
    
    func callToGetTokenAPI ()
    {
        if APIManagerSharedInstance.isNetworkConnected() {
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            APIManagerSharedInstance.callPostService(postdata: [:], token:"", type: "AUTH", urlString: "") { (result, error) in
                
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    if result["error"] == nil {
                        self.tokenStr = result["access_token"] as! String
                    }
                    else {
                        
                        if result["message"] == nil {
                            APIManagerSharedInstance.showAlert(message: result["message"] as! String)
                        }
                        else {
                            APIManagerSharedInstance.showAlert(message: result["error_description"] as! String)
                        }
                    }
                }
            }
        }
        else {
            APIManagerSharedInstance.showAlert(message: Constants.noInternet)
        }
    }
    
    func callUpdatePasswordAPI (dict:NSDictionary) {
        
        if APIManagerSharedInstance.isNetworkConnected() {
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            APIManagerSharedInstance.callPostService(postdata: dict, token:"", type: "PUT", urlString: APIs.CHANGE_PWD as NSString ) { (result, error) in
                
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let errorvalue : String = result["error"] as! String
                    if (errorvalue == "0") {
                        
                        Constants.userDefaultObj.setValue(self.txtNewPwd.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), forKey: "Password")
                        Constants.userDefaultObj.synchronize()
                        APIManagerSharedInstance.showAlert(message: result["message"] as! String)
                        _ =  self.navigationController?.popToRootViewController(animated: true)
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
    
    // MARK: - UITextfield Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
