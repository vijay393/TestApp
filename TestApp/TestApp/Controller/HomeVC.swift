//
//  HomeVC.swift
//  TestApp
//
//  Created by Nilesh on 12/12/16.
//  Copyright © 2016 Nilesh. All rights reserved.
//

import UIKit
import MBProgressHUD

class HomeVC: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet weak var userListTblView: UITableView!
    var userList = [[String:AnyObject]]()
    var tokenStr : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userListTblView.tableFooterView = UIView()
        
        self.title = "Home"
        
        let ChangePwd : UIBarButtonItem = UIBarButtonItem(title: "Change Password", style: .plain, target: self, action: #selector(HomeVC.changePwdAction))
        self.navigationItem.rightBarButtonItem = ChangePwd
        
        let logout : UIBarButtonItem = UIBarButtonItem(title: "logout", style: .plain, target: self, action: #selector(HomeVC.logoutAction))
        self.navigationItem.leftBarButtonItem = logout
        
        self.userListTblView.estimatedRowHeight = 200
        self.userListTblView.rowHeight = UITableViewAutomaticDimension
        
        self.callToGetTokenAPI()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let emailLbl = cell.viewWithTag(100) as! UILabel
        let nameLbl = cell.viewWithTag(101) as! UILabel
        
        let dataSource : NSDictionary = self.userList[indexPath.row] as NSDictionary
        
        emailLbl.text = "Email: " + (dataSource["email"] as! String)
        nameLbl.text = "Name: " + (dataSource["firstname"] as! String) + " " + (dataSource["lasename"] as! String)
        
        return cell
        
    }
    
    // MARK: - Actions
    
    func changePwdAction() {
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "ChangePwd") as! ChangePwd
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func logoutAction() {
        
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - API Calling
    
    func callUserListAPI () {
        
        if APIManagerSharedInstance.isNetworkConnected() {
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            APIManagerSharedInstance.callPostService(postdata: [:], token:self.tokenStr as NSString, type: "GET", urlString: APIs.GET_ALL_USER as NSString ) { (result, error) in
                
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let errorvalue : String = result["error"] as! String
                    if (errorvalue == "0") {
                        
                        self.userList = result["data"] as! [[String:AnyObject]]
                        self.userListTblView.reloadData()
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
    
    func callToGetTokenAPI () {
        
        if APIManagerSharedInstance.isNetworkConnected() {
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            APIManagerSharedInstance.callPostService(postdata: [:], token:"", type: "AUTH", urlString: "") { (result, error) in
                
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    if result["error"] == nil {
                        let temp1 = result["token_type"] as! String
                        let temp2 = result["access_token"] as! String
                        self.tokenStr = temp1 + " " + temp2
                        
                        self.callUserListAPI()
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
}
