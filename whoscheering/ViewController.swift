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
var avgOffset: Double = 0

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
            //check if they own the product or not
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
                self.actionButton.setTitle("Buy $x.xx", forState: .Normal)
            }
            else{
                self.startCheeringButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Start Flash", forState: .Normal)
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
            if !database.executeUpdate("create table offsets(id integer primary key autoincrement, offset real)", withArgumentsInArray: nil) {
                println("create table failed: \(database.lastErrorMessage()), probably already created")
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
            
            
            //load offsets
            var averageOffset:[Double] = []
            averageOffset.append(getOffset())
            averageOffset.append(getOffset())
            averageOffset.append(getOffset())
            let average = averageOffset.reduce(0) { $0 + $1 } / Double(averageOffset.count)
            println( average )
            database.executeUpdate("insert into offsets values (NULL, '\(String(stringInterpolationSegment: average))')", withArgumentsInArray: nil)
            
            //average all of the stored offsets
            var offsets:[Double] = []
            if let rs = database.executeQuery("SELECT * FROM offsets LIMIT 50", withArgumentsInArray: nil) {
                while rs.next() {
                    var offset = rs.doubleForColumn("offset")
                    offsets.append(offset)
                }
                avgOffset = offsets.reduce(0) { $0 + $1 } / Double(offsets.count)
                println(avgOffset)
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
        var alert = UIAlertController(title: "In App Purchase in progress", message: "Buy this flash, get first free, or start cheering if owned. Use \"Test\" above while in testing.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
        //Buy the cheer
        //OR Start cheering
    }
    
    func getOffset() -> Double {
        var offset : Double = 0
        if Reachability.isConnectedToNetwork() == true {
            let ct = NSDate().timeIntervalSince1970
            let serverEpochStr: String = parseJSON( getJSON("http://alignthebeat.appspot.com") )["epoch"] as! String
            let serverEpoch = (serverEpochStr as NSString).doubleValue
            let nct = NSDate().timeIntervalSince1970
            let ping = nct - ct
            offset = serverEpoch - nct + (ping / 2.0)
        }
        return offset
    }
    
    func getJSON(urlToRequest: String) -> NSData{
        return NSData(contentsOfURL: NSURL(string: urlToRequest)!)!
    }
    
    func parseJSON(inputData: NSData) -> NSDictionary{
        var error: NSError?
        var boardsDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers, error: &error) as! NSDictionary
        
        return boardsDictionary
    }
    
}