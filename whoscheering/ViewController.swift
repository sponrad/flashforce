//
//  ViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/21/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit
import StoreKit

var ffdbLoaded = false
var selectedId: Int32 = 0

class ViewController: UIViewController, SKStoreProductViewControllerDelegate {

    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var outfitLabel: UILabel!
    @IBOutlet weak var startCheeringButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var testCheerButton: UIBarButtonItem!
    
    var team = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.teamLabel.text = self.team
        self.outfitLabel.text = ""
        
        self.navigationItem.hidesBackButton = true;
        
        if (SKPaymentQueue.canMakePayments()){
            println("can make payments")
        }
        else {
            println("no payment support")
        }
        
        
        
        ///////////////////////////   flash button logic
        if (self.team == ""){
            self.startCheeringButton.enabled = false
            self.startCheeringButton.alpha = 0.3
            self.actionButton.hidden = true
            self.testCheerButton.enabled = false
        }
        else {
            //check if they own the theme or not
            //if owned: display the start cheer button
            //if not owned:
            //check Keychain for if first theme has been purchased
            //TegKeychain.clear()
            if var result = TegKeychain.get("visitedcheer") {   //this is currently set in CheerViewController
                println("In Keychain: \(result)")
            } else {
                println("no value in keychain")
            }
            //if yes then display the normal IAP button
            //if no, give option to grant this theme for free, with confirmation
            
            if contains(["Duke", "Fireworks", "Kings"], self.team){
                //example not owned
                self.startCheeringButton.enabled = true
                self.testCheerButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Buy Cheer $x.xx", forState: .Normal)
            }
            else{
                self.startCheeringButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Start Cheering", forState: .Normal)
                self.outfitLabel.text = ""
            }
        }
        
        
        
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let path = documentsFolder.stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            println("Unable to open database")
            return
        }
        
        
       
        ///////////////////////////   code to load the database
        if (ffdbLoaded==false){
            database.executeUpdate("DROP TABLE cheers", withArgumentsInArray: nil)
            
            if !database.executeUpdate("create table cheers(id integer primary key autoincrement, storecode text, name text, category text, pattern text, timing real, price real, pattern1 text, pattern2 text, pattern3 text, pattern4 text, pattern5 text)", withArgumentsInArray: nil) {
                println("create table failed: \(database.lastErrorMessage())")
            }
            database.executeUpdate("DELETE FROM cheers", withArgumentsInArray: nil)
            //loop through initialData to build the database
            for record in StoreData.initialData {
                var pattern = record[5]  //stored in [5] through [9]...but may be empty
                var pattern1 = record[5]
                var pattern2 = record[6]
                var pattern3 = record[7]
                var pattern4 = record[8]
                var pattern5 = record[9]
                let timing = 2.0
                let price = 3.99
                database.executeUpdate("insert into cheers values (NULL, '\(record[0])', '\(record[2])', '\(record[1])', '\(pattern)', \(timing), \(price), '\(pattern1)', '\(pattern2)', '\(pattern3)', '\(pattern4)', '\(pattern5)')", withArgumentsInArray: nil)
            }
            ffdbLoaded = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBarHidden = false
        super.viewWillAppear(animated)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        if (navigationController?.topViewController != self) {
            navigationController?.navigationBarHidden = false
        }
        super.viewWillDisappear(animated)
    }

    @IBAction func actionButtonTapped(sender: AnyObject) {
        var alert = UIAlertController(title: "Future functionality", message: "Buy this cheer, get first free, or start cheering if owned", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
        //Buy the cheer
        //OR Start cheering
    }
    
}