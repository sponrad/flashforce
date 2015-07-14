//
//  CheerViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/22/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

class CheerViewController: UIViewController {
    

    
    var color = 0
    var colors = ["D4001F", "000000"]
    var interval = 2.0 //interval in s
    var timer : NSTimer!
    
   
    @IBOutlet weak var syncingLabel: UILabel!
    @IBOutlet weak var shakeLabel: UILabel!
    @IBOutlet weak var stopCheeringButton: UIButton!
    
    @IBAction func clickStopCheeringButton(sender: AnyObject) {
        let mainStoryboard = UIStoryboard(name: "Storyboard", bundle: NSBundle.mainBundle())
        let vc : UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("ViewController") as! UIViewController
        self.presentViewController(vc, animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // // // GET INFO FROM DATABASE // // //
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let path = documentsFolder.stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            println("Unable to open database")
            return
        }
        
        if let rs = database.executeQuery("SELECT * FROM cheers WHERE id=\(String(selectedId))", withArgumentsInArray: nil) {
            while rs.next() {
                colors = [String]()
                if (rs.stringForColumn("pattern1") != ""){
                    colors.append(rs.stringForColumn("pattern1"))
                }
                if (rs.stringForColumn("pattern2") != ""){
                    colors.append(rs.stringForColumn("pattern2"))
                }
                if (rs.stringForColumn("pattern3") != ""){
                    colors.append(rs.stringForColumn("pattern3"))
                }
                if (rs.stringForColumn("pattern4") != ""){
                    colors.append(rs.stringForColumn("pattern4"))
                }
                if (rs.stringForColumn("pattern5") != ""){
                    colors.append(rs.stringForColumn("pattern5"))
                }
                //interval =
            }
        } else {
            println("select failed: \(database.lastErrorMessage())")
        }
        // // // END GET INFO FROM DATABASE // // //

        
        TegKeychain.set("visitedcheer", value: "yes!")               //only for testing
        
        self.view.backgroundColor = colorWithHexString(colors[0])
        self.syncingLabel.text = "syncing..."
        UIApplication.sharedApplication().idleTimerDisabled = true   //screen will not dim
        let modnumber = Double(colors.count) * interval
        
        let ct = NSDate().timeIntervalSince1970
        
        //grab the server time
        let serverEpochStr: String = parseJSON( getJSON("http://alignthebeat.appspot.com") )["epoch"] as! String
        let serverEpoch = (serverEpochStr as NSString).doubleValue
        
        let nct = NSDate().timeIntervalSince1970
        println("nct: \(nct)")
        println("server: \(serverEpoch)")
        let ping = nct - ct
        
        println("ping: \(ping)")
        
        var offset = serverEpoch - nct + (ping / 2.0)
        
        println("offset: \(offset)")
        
        var modOffset = (NSDate().timeIntervalSince1970 + offset) % modnumber
        var modDelay = (interval * Double(colors.count)) - modOffset
        
        delay(modDelay){
            self.timer = NSTimer.scheduledTimerWithTimeInterval(self.interval , target: self, selector: Selector("update"), userInfo: nil, repeats: true)
            //self.timer.tolerance = 0.1
            self.syncingLabel.text = ""
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func update() {
        color += 1
        if (color == colors.count){
            color = 0
        }
        self.view.backgroundColor = colorWithHexString(colors[color])
    }
    
    func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substringFromIndex(1)
        }
        
        if (count(cString) != 6) {
            return UIColor.grayColor()
        }
        
        var rString = (cString as NSString).substringToIndex(2)
        var gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        var bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func getJSON(urlToRequest: String) -> NSData{
        return NSData(contentsOfURL: NSURL(string: urlToRequest)!)!
    }
    
    func parseJSON(inputData: NSData) -> NSDictionary{
        var error: NSError?
        var boardsDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers, error: &error) as! NSDictionary
        
        return boardsDictionary
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if motion == .MotionShake {
            self.shakeLabel.text = "D!"
            
        }
    }

}
