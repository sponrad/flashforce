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
    var interval = 0.25 //base interval
    var timer : NSTimer!
    var brightnessArray = [Double]()
    
    @IBOutlet weak var syncingLabel: UILabel!
    @IBOutlet weak var shakeLabel: UILabel!
    @IBOutlet weak var stopCheeringButton: UIButton!
    
    @IBAction func clickStopCheeringButton(sender: AnyObject) {
        let mainStoryboard = UIStoryboard(name: "Storyboard", bundle: NSBundle.mainBundle())
        let vc : UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("ViewController")
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cheering = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"mainFlash", name:UIApplicationDidBecomeActiveNotification, object: nil)
        mainFlash()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mainFlash(){
        UIScreen.mainScreen().brightness = CGFloat(1.0)
        
        if (cheering == true){
            self.timer?.invalidate()  //this resets the cheer sequence but does not check for a new time
            //checkOffsetAge()
        }
        else {
            //do nothing somehow
            return
        }
        
        // // // GET INFO FROM DATABASE // // //
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        if let rs = database.executeQuery("SELECT * FROM patterns WHERE id=\(String(selectedId))", withArgumentsInArray: nil) {
            while rs.next() {
                var timing = rs.stringForColumn("timing").componentsSeparatedByString("_")
                //print("Here come the codes")
                colors = [String]()
                if (rs.stringForColumn("pattern1") != ""){
                    for var i = 0.0; i < ( Double(timing[0])); i++ {
                        colors.append(rs.stringForColumn("pattern1"))
                        brightnessArray.append(relativeBrightness(rs.stringForColumn("pattern1")))
                    }
                }
                if (rs.stringForColumn("pattern2") != ""){
                    for var i = 0.0; i < ( Double(timing[1])); i++ {
                        colors.append(rs.stringForColumn("pattern2"))
                        brightnessArray.append(relativeBrightness(rs.stringForColumn("pattern2")))
                    }
                }
                if (rs.stringForColumn("pattern3") != ""){
                    for var i = 0.0; i < ( Double(timing[2])); i++ {
                        colors.append(rs.stringForColumn("pattern3"))
                        brightnessArray.append(relativeBrightness(rs.stringForColumn("pattern3")))
                    }
                }
                if (rs.stringForColumn("pattern4") != ""){
                    for var i = 0.0; i < ( Double(timing[3])); i++ {
                        colors.append(rs.stringForColumn("pattern4"))
                        brightnessArray.append(relativeBrightness(rs.stringForColumn("pattern4")))
                    }
                }
                if (rs.stringForColumn("pattern5") != ""){
                    for var i = 0.0; i < ( Double(timing[4])); i++ {
                        colors.append(rs.stringForColumn("pattern5"))
                        brightnessArray.append(relativeBrightness(rs.stringForColumn("pattern5")))
                    }
                }
            }
        } else {
            print("select failed: \(database.lastErrorMessage())")
        }
        database.close()
        // // // END GET INFO FROM DATABASE // // //
        
        self.view.backgroundColor = colorWithHexString(colors[0])
        
        self.syncingLabel.text = ""
        UIApplication.sharedApplication().idleTimerDisabled = true   //screen will not dim
        let modnumber = Double(colors.count) * interval
        
        var modOffset: Double = 1
        var modDelay: Double = 1
        
        //get what color we are on
        modOffset = (NSDate().timeIntervalSince1970 + avgOffset) % modnumber
        self.color = Int( modOffset / interval )
        
        //small delay to next color change
        modDelay = interval - ((NSDate().timeIntervalSince1970 + avgOffset) % interval)
        
        delay(modDelay){
            self.timer = NSTimer.scheduledTimerWithTimeInterval(self.interval , target: self, selector: Selector("update"), userInfo: nil, repeats: true)
            //self.timer.tolerance = 0.1
            self.syncingLabel.text = ""
            self.view.backgroundColor = self.colorWithHexString(self.colors[self.color])
            UIScreen.mainScreen().brightness = CGFloat( self.brightnessArray[self.color])
        }
        
        if (cheering == true){
            print("cheer loaded")
        }
        
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
        
        if (cString.characters.count != 6) {
            return UIColor.grayColor()
        }
        
        let rString = (cString as NSString).substringToIndex(2)
        let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
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
        do{
            let boardsDictionary: NSDictionary = try NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            
            return boardsDictionary
        }
        catch{
            print("error")
            return NSDictionary()
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    //revert brightness
    override func viewWillDisappear(animated : Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParentViewController()==true){
            // Your code...
            UIScreen.mainScreen().brightness = oldBrightness
            cheering = false
        }
    }
    
    func relativeBrightness(hex:String) -> Double {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substringFromIndex(1)
        }
        
        let rString = (cString as NSString).substringToIndex(2)
        let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        //print(r)
        //print(g)
        //print(b)
        
        var brightness : Double = (Double(r) * Double(r) * 0.241)
        brightness = brightness + (Double(g) * Double(g) * 0.691)
        brightness = brightness + (Double(b) * Double(b) * 0.068)
        brightness = sqrt( brightness )
        
        //print(brightness)
        //need a scale from 90 to 100
        //brightness of 255 returns 80 or low point, 0 returns 100 or full value
        let modified = (90.0 + (10.0 * (255.0 - Double(brightness) ) / 255.0 ))
        //print(modified)
        return modified
    }
    
    func checkOffsetAge(){
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        if let rs = database.executeQuery("SELECT * FROM offsets LIMIT 1", withArgumentsInArray: nil) {
            print("Here is the check for staleness of a sync")
            while rs.next() {
                let current = Double(NSDate().timeIntervalSince1970)
                print(current)
                print(rs.doubleForColumn("timestamp"))
                if ( (current - rs.doubleForColumn("timestamp")) < offsetAgeForResync){  //anything one hour or more recent
                    //do nothing
                }
                else{
                    cheering = false
                    //redirect to viewcontroller
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("ViewController") as UIViewController
                    self.navigationController?.pushViewController(nextViewController, animated: true)
                }
            }
        }
    }
    
}
