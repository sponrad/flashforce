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
var selectedId: Int32 = 9999999
var avgOffset: Double = 0.0
var cheering = false
var actionButtonStatus = "None"
var selectedStoreId: String = ""
var selectedPrice: String = ""
var oldBrightness: CGFloat = 0.5
var flashAble = false
var offsetAgeForResync = 600.0 // double seconds

let freeFlashString = "ffb001"       //keychain reference, if you change this, everyones free flash resets
let dbVersionString = "ffdb004"       //keychain reference, increment this to force database update of pattern data


//class ViewController: UIViewController, SKStoreProductViewControllerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
class ViewController: UIViewController, SKStoreProductViewControllerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {


    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var outfitButton: UIButton!
    @IBOutlet weak var teamButton: UIButton!
    @IBOutlet weak var tapButton: UIButton!
    @IBOutlet weak var labelTopArrow: UILabel!
    @IBOutlet weak var labelBottomArrow: UILabel!
    @IBOutlet weak var labelMiddleArrow: UILabel!
    
    @IBOutlet weak var grayOverBrowse: UILabel!
    @IBOutlet weak var grayUnderBrowse: UILabel!
    @IBOutlet weak var grayUnderTeam: UILabel!
    @IBOutlet weak var grayOverFlash: UILabel!
    
    @IBOutlet weak var flashForwardBoxes: UIImageView!
    
    var team = String()   // set from the secondbrowseviewcontroller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialStates()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"checkOffsetAge", name:UIApplicationDidBecomeActiveNotification, object: nil) // adding observer for syncing
        
        databaseCheck() // check database and load data if needed
        
        checkOffsetAge() //change appearance of flash force icon based on offset age, and run performSync if needed
        
        updateDisplay()  //update screen based on pattern and ownership
        
        setAverageOffset() //set the offset used while flashing
        
        if (isAppAlreadyLaunchedOnce() == false){
            firstTimeBoot()  //get owned IAPs and show tutorial images
        }
        
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)

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
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }

    @IBAction func actionButtonTapped(sender: AnyObject) {
        switch actionButtonStatus {
            case "flash":
                if flashAble {
                    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let setViewController = mainStoryboard.instantiateViewControllerWithIdentifier("cheer")
                    navigationController?.pushViewController(setViewController, animated: true)
                }
                else {
                    print("do not flash if no offsets stored")
                    let alert = UIAlertController(title: "Unable to Flash", message: "Please connect to the internet and restart Flash Force", preferredStyle: UIAlertControllerStyle.Alert)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: purchaseFreeFlash ))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            case "getfree":
                let alert = UIAlertController(title: "Free Flash", message: "Do you want to use your one free flash for this product?", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: purchaseFreeFlash ))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            case "buy":
                self.actionButton.setTitle("Purchasing", forState: UIControlState.Normal)
                actionButtonStatus = "purchasing"
                buyNonConsumable()
            case "sync":
                self.checkOffsetAge()
            default:
                print("no action")
        }
    }
    
    @IBAction func tapButtonTapped(sender: AnyObject) {
        performSync()
        //checkOffsetAge()
        updateDisplay()
    }
    
    func performSync(){
        if (cheering){
            return
        }
        
        self.actionButton.setTitle("Syncing...", forState: UIControlState.Normal)
        
        let url = NSBundle.mainBundle().URLForResource("animated-threeboxes-10-13", withExtension: "gif")
        let imageData = NSData(contentsOfURL: url!)
        // Returns an animated UIImage
        self.flashForwardBoxes.image = UIImage.animatedImageWithData(imageData!)
        
        print("PERFORM SYNC resetting the offsets database")
        let qualityOfServiceClass = QOS_CLASS_USER_INTERACTIVE
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        var synced = false
        dispatch_async(backgroundQueue, {
            print("This is run on the other queue")
            
            ///////////////////////////   connect to the database
            let reachability = Reachability.reachabilityForInternetConnection()
            if reachability!.isReachable() {
                let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
                let database = FMDatabase(path: path)
                if !database.open() {
                    print("Unable to open database")
                    return
                }
                database.executeUpdate("DROP TABLE offsets", withArgumentsInArray: nil)
                
                
                if !database.executeUpdate("create table offsets(id integer primary key autoincrement, offset real, timestamp real)", withArgumentsInArray: nil) {
                    print("create table failed: \(database.lastErrorMessage()), probably already created")
                }
                
                //load offsets
                var offsets:[Double] = []
                for var index = 0; index < 6; index++ {
                    offsets.append(self.getOffset())
                }

                let average = offsets.reduce(0) { $0 + $1 } / Double(offsets.count)
                print("average \(average)")
                print("standard deviation \(self.standardDeviation(offsets))")
                
                var cleanedOffsets:[Double] = []
                
                for offset in offsets {
                    if ( abs(offset - average) < self.standardDeviation(offsets) ){  //this removes values above and below std
                        cleanedOffsets.append(offset)
                    }
                }
                
                let cleanedAverage = cleanedOffsets.reduce(0) { $0 + $1 } / Double(cleanedOffsets.count)
                avgOffset = cleanedAverage
                print("cleaned average: \(avgOffset)")
                
                database.executeUpdate("insert into offsets values (NULL, '\(String(stringInterpolationSegment: average))','\(String(stringInterpolationSegment: NSDate().timeIntervalSince1970))')", withArgumentsInArray: nil)
                
                database.close()
                
                if (avgOffset < 200){ //make sure the 1000 return for bad connection has not taken over and skewed the offset
                    synced = true
                }
            }
            else {
                print("not reachable")
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //print("This is run on the main queue, after the previous code in outer block")
                if (synced){
                    self.changeFlashImage()
                    flashAble = true
                }
                else {
                    self.flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes-gray.gif")
                }
                self.updateDisplay()
                
            })
        })
    }
    
    func standardDeviation(arr : [Double]) -> Double
    {
        let length = Double(arr.count)
        let avg = arr.reduce(0, combine: {$0 + $1}) / length
        let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, combine: {$0 + $1})
        return sqrt(sumOfSquaredAvgDiff / length)
    }
    
    func reachabilityChanged(notification: NSNotification){
        print("reachability changed")
        print(notification.description)
    }
    
    func changeFlashImage(){
        self.flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes.gif")
    }
    
    func getOffset() -> Double {
        var offset : Double = 0
        var ping = 100.0 // any value larger than the test
        var count = 0
        
        while (ping > 0.7){
            if (count > 20){
                return 1000.0
            }
            let ct = NSDate().timeIntervalSince1970
            let serverEpochStr: String = parseJSON( getJSON("https://alignthebeat.appspot.com") )["epoch"] as! String
            let serverEpoch = (serverEpochStr as NSString).doubleValue
            let nct = NSDate().timeIntervalSince1970
            ping = nct - ct
            print("ping \(ping)")
            offset = serverEpoch - nct + ping
            count += 1
        }
        
        //offset = serverEpoch - nct
        print("offset \(offset)")
        return offset
    }
    
    func getJSON(urlToRequest: String) -> NSData{
        var data = NSData()
        if let url = NSURL(string: urlToRequest){
            if let tempData = NSData(contentsOfURL: url){
                data = tempData
            }
        }
        return data
    }
    
    func parseJSON(inputData: NSData) -> NSDictionary{
        do {
            let boardsDictionary: NSDictionary = try NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            return boardsDictionary
        }
        catch{
            print("error")
            return NSDictionary()
        }
    }
    
    func drawRect(size: CGSize, color: UIColor) -> UIImage {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        // Setup complete, do drawing here
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
        CGContextFillRect(context, bounds);
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func drawBordered(size: CGSize, color: UIColor) -> UIImage {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        //Draw fill
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
        CGContextFillRect(context, bounds);
        
        // Draw Border
        CGContextSetStrokeColorWithColor(context, UIColor.grayColor().CGColor)
        CGContextSetLineWidth(context, 2.0)
        CGContextStrokeRect(context, bounds)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
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
    
    //purchase a flash for free, set the token, and change the action button
    func purchaseFreeFlash (alert: UIAlertAction!){
        TegKeychain.set(String(freeFlashString), value: selectedStoreId)
        self.actionButton.enabled = true
        self.actionButton.hidden = false
        self.actionButton.setTitle("Flash", forState: UIControlState.Normal)
        actionButtonStatus = "flash"
        
        addOwnedPattern(String(selectedStoreId))
    }
    
    func buyNonConsumable (){
        print("About to fetch the products");
        // We check that we are allow to make the purchase.
        if (SKPaymentQueue.canMakePayments())
        {
            let productID:NSSet = NSSet(object: String(selectedStoreId));
            let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>);
            productsRequest.delegate = self;
            productsRequest.start();
            print("Fetching Products");
        }else{
            print("can't make purchases");
        }
    }
    
    func productsRequest (request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("got the request from Apple")
        let count : Int = response.products.count
        if (count>0) {
            //var validProducts = response.products
            let validProduct: SKProduct = response.products[0]
            if (validProduct.productIdentifier == String(selectedStoreId)) {
                print(validProduct.localizedTitle)
                print(validProduct.localizedDescription)
                print(validProduct.price)
                buyProduct(validProduct);
            } else {
                print(validProduct.productIdentifier)
            }
        } else {
            print("nothing")
        }
    }
    
    func buyProduct(product: SKProduct){
        print("Sending the Payment Request to Apple");
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment);
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
        print("Received Payment Transaction Response from Apple Viewcontroller");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .Purchased, .Restored:
                    print("Product Purchased/Restored");
                    addOwnedPattern(String(transaction.payment.productIdentifier))
                    doOwnershipChecks()
                    
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                case .Failed:
                    print("Purchased Failed");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    doOwnershipChecks()
                    break;
                    // case .Restored:
                    //[self restoreTransaction:transaction];
                default:
                    break;
                }
            }
        }
    }
    
    func addOwnedPattern(storeId: String, var patternId: String = ""){
        print("addOwnedPattern")
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        var name = ""
        if let rs = database.executeQuery("SELECT * FROM patterns WHERE storecode='\(String(storeId))'", withArgumentsInArray: nil) {
            while rs.next() {
                name = rs.stringForColumn("name") + " " + rs.stringForColumn("alt1")
                patternId = rs.stringForColumn("id")
            }
        }
        
        database.executeUpdate("insert into ownedpatterns values (NULL, '\(storeId)', '\(name)', '\(patternId)' )", withArgumentsInArray: nil)
        database.close()
        
    }
    
    func listOfOwnedPatterns() -> Array<String> {
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
        }
        
        var ownedPatterns = [String]()
        
        if let rs = database.executeQuery("SELECT * FROM ownedpatterns", withArgumentsInArray: nil) {
            while rs.next() {
                if (rs.stringForColumn("storecode") != ""){
                    ownedPatterns.append(rs.stringForColumn("storecode"))
                }
            }
        }
        
        database.close()
        
        return ownedPatterns
    }
    
    func firstTimeBoot(){
        print("performing first boot")
        performSync()
        
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
        }
        
        ////////////////get any keychain flashes
        if let result = TegKeychain.get(String(freeFlashString)) {
            print(result)
            addOwnedPattern(String(result))
        }
        
        //getOwnedFlashes()
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("tutorial1") as UIViewController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func isAppAlreadyLaunchedOnce()->Bool{
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let _ = defaults.stringForKey("isAppAlreadyLaunchedOnce"){
            print("App already launched")
            return true
        }else{
            defaults.setBool(true, forKey: "isAppAlreadyLaunchedOnce")
            print("App launched first time")
            return false
        }
    }
    
    func loadDatabase(){
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        database.executeUpdate("DROP TABLE patterns", withArgumentsInArray: nil)
        
        if !database.executeUpdate("create table patterns(id integer primary key autoincrement, storecode text, name text, groupid text, category text, pattern text, timing text, price real, pattern1 text, pattern2 text, pattern3 text, pattern4 text, pattern5 text, alt1 text)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage())")
        }
        if !database.executeUpdate("create table offsets(id integer primary key autoincrement, offset real, timestamp real)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage()), probably already created")
        }
        if !database.executeUpdate("create table ownedpatterns(id integer primary key autoincrement, storecode text, name text, patternid integer)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage()), probably already created")
        }
        database.executeUpdate("DELETE FROM patterns", withArgumentsInArray: nil)
        
        
        let fileLocation = NSBundle.mainBundle().pathForResource("ffinput", ofType: "csv")!
        let error: NSErrorPointer = nil
        if let csv = CSV(contentsOfFile: fileLocation, error: error) {
            //loop through initialData to build the database
            for record in csv.rows {
                let pattern = record["color1"]!
                let pattern1 = record["color1"]!
                let pattern2 = record["color2"]!
                let pattern3 = record["color3"]!
                let pattern4 = record["color4"]!
                let pattern5 = record["color5"]!
                let timing = record["timing"]!
                let price = record["price"]!
                database.executeUpdate("insert into patterns values (NULL, '\(record["productid"]!)', '\(record["name"]!)', '\(record["groupid"]!)', '\(record["category"]!)', '\(pattern)', '\(timing)', \(price), '\(pattern1)', '\(pattern2)', '\(pattern3)', '\(pattern4)', '\(pattern5)', '\(record["alternate"]!)')", withArgumentsInArray: nil)
            }
        }
        
        //add one offset at startup
        database.executeUpdate("insert into offsets values (NULL, '0.0','0.0')", withArgumentsInArray: nil)
        
        let reachability = Reachability.reachabilityForInternetConnection()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        reachability!.startNotifier()
        
        ffdbLoaded = true
    }
    
    func initialStates(){
        cheering = false
        self.navigationItem.hidesBackButton = false;
        self.outfitButton.enabled = false
        self.outfitButton.hidden = true
        self.teamButton.enabled = false
        self.teamButton.hidden = true
        self.teamButton.setTitle("", forState: UIControlState.Normal)
        self.tapButton.setTitle("", forState: UIControlState.Normal)
        self.labelBottomArrow.hidden = true
        self.labelMiddleArrow.hidden = true
        
        grayOverFlash.hidden = true
        grayUnderTeam.hidden = true
        
        UIScreen.mainScreen().brightness = oldBrightness
        
        flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes-gray.gif")
        
        UIApplication.sharedApplication().idleTimerDisabled = false   //screen will dim while not cheering

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
                    self.changeFlashImage()
                    flashAble = true
                }
                else{
                    self.flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes-gray.gif")
                    performSync()
                    //flashAble = false  //temporary... should allow a flash even with a gray/no connection
                    actionButtonStatus = "sync"
                }
            }
        }

    }
    
    func setAverageOffset(){
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        //average all of the stored offsets
        var offsets:[Double] = []
        if let rs = database.executeQuery("SELECT * FROM offsets LIMIT 50", withArgumentsInArray: nil) {
            while rs.next() {
                let nRows = rs.intForColumnIndex(0)
                if (nRows > 0){
                    flashAble = true   //allow flash if there is at least one offset stored
                }
                let offset = rs.doubleForColumn("offset")
                offsets.append(offset)
            }
            avgOffset = offsets.reduce(0) { $0 + $1 } / Double(offsets.count)
            print(avgOffset)
        }
    }
    
    func doOwnershipChecks(){
        //check if they own the product or not
        var owned = false  //check against app store
        
        //check ownership against keychain
        if (TegKeychain.get(String(freeFlashString)) != nil){
            if TegKeychain.get(String(freeFlashString))! == selectedStoreId {
                owned = true
            }
                
            else { //check ownership aginst premade list of owned
                if listOfOwnedPatterns().contains( String(selectedStoreId) ) {
                    owned = true
                }
                else {
                    //check ownership in apple store to see if owned
                    //if (SKPaymentQueue.canMakePayments()){
                    //    SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
                    //}
                }
            }
        }
        //if owned: display the start flash button
        if (selectedPrice == "0.0"){
            owned = true
        }
        if (owned == true || selectedPrice == "0.0"){
            self.actionButton.enabled = true
            self.actionButton.hidden = false
            self.actionButton.setTitle("Flash", forState: UIControlState.Normal)
            actionButtonStatus = "flash"
        }
        //if not owned:
        if (owned == false) {
            //check Keychain for if first theme has been purchased
            if let result = TegKeychain.get(String(freeFlashString)) {   //this is set when the flash button is tapped
                print("In Keychain: \(result)")
                //if yes, display the normal IAP button
                actionButtonStatus = "buy"
                self.actionButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Buy $\(selectedPrice)", forState: UIControlState.Normal)
            } else {
                //if no, give option to grant this theme for free, with confirmation
                actionButtonStatus = "getfree"
                self.actionButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Get for Free", forState: UIControlState.Normal)
            }
        }
    }
    
    func getPatternInformation(){
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        self.teamButton.hidden = false
        self.teamButton.enabled = true
        
        //teambutton underline
        self.grayUnderTeam.hidden = false
        
        //draw the rect over the flash button
        grayOverFlash.hidden = false
        self.labelMiddleArrow.hidden = false
        
        //check if there are alternates for the selected team (depends of flash name being somewhat unique)
        if let count = database.intForQuery("SELECT COUNT(name) FROM patterns WHERE name='\(self.team)'") {
            if (count > 1){
                self.outfitButton.enabled = true
                self.outfitButton.hidden = false
                self.outfitButton.setTitle("Choose Alternate", forState: UIControlState.Normal)
                self.labelBottomArrow.hidden = false
            }
            else {
                self.outfitButton.enabled = false
                self.outfitButton.hidden = true
            }
        } else {
            print("select failed: \(database.lastErrorMessage())")
        }
        
        //display correct information
        if let rs = database.executeQuery("SELECT * FROM patterns WHERE id=\(String(selectedId))", withArgumentsInArray: nil) {
            while rs.next() {
                self.browseButton.setTitle(rs.stringForColumn("category"), forState: UIControlState.Normal)
                self.teamButton.setTitle(rs.stringForColumn("name"), forState: UIControlState.Normal)
                self.team = rs.stringForColumn("name")
                self.outfitButton.setTitle(rs.stringForColumn("alt1"), forState: UIControlState.Normal)
                if rs.stringForColumn("alt1").isEmpty {
                    self.outfitButton.setTitle("Home", forState: UIControlState.Normal)
                }
                var timing = rs.stringForColumn("timing").componentsSeparatedByString("_")
                
                selectedStoreId = rs.stringForColumn("storecode")
                selectedPrice = rs.stringForColumn("price")
                
                ///////////draw color boxes for selected flash
                var colors = [String]()
                if (rs.stringForColumn("pattern1") != ""){
                    for var i = 0.0; i < ( Double(timing[0])); i++ {
                        colors.append(rs.stringForColumn("pattern1"))
                    }
                }
                if (rs.stringForColumn("pattern2") != ""){
                    for var i = 0.0; i < ( Double(timing[1])); i++ {
                        colors.append(rs.stringForColumn("pattern2"))
                    }
                }
                if (rs.stringForColumn("pattern3") != ""){
                    for var i = 0.0; i < ( Double(timing[2])); i++ {
                        colors.append(rs.stringForColumn("pattern3"))
                    }
                }
                if (rs.stringForColumn("pattern4") != ""){
                    for var i = 0.0; i < ( Double(timing[3])); i++ {
                        colors.append(rs.stringForColumn("pattern4"))
                    }
                }
                if (rs.stringForColumn("pattern5") != ""){
                    for var i = 0.0; i < ( Double(timing[4])); i++ {
                        colors.append(rs.stringForColumn("pattern5"))
                    }
                }
                
                let screenSize = self.view.bounds
                let boxSize = (Double(screenSize.width) / Double(colors.count))
                print("boxSize: \(boxSize)")
                //let startingX = (Double(screenSize.width) / 2.0) - (boxSize * Double(colors.count)) + 10.0
                let startingX = 0.0
                for (index, color) in colors.enumerate() {
                    let imageSize = CGSize(width: (boxSize + 1), height: 40)   //adding one to cover the pixel fraction
                    let xCoord = CGFloat((Double(index) * boxSize) + startingX)
                    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: xCoord, y: CGFloat(screenSize.height - 115)), size: imageSize))
                    self.view.addSubview(imageView)
                    //let image = drawBordered(imageSize, color: colorWithHexString(color))
                    let image = drawRect(imageSize, color: colorWithHexString(color))
                    imageView.image = image
                }
            }
        }
        else {
            print("select failed: \(database.lastErrorMessage())")
        }
    }
    
    func updateDisplay(){
        if (self.team == ""){
            self.actionButton.enabled = false
            self.actionButton.alpha = 0.3
            self.actionButton.hidden = true
            self.actionButton.enabled = false
        }
        else {
            getPatternInformation() //gets pattern info and does screen updates
            if (flashAble){
                doOwnershipChecks() //updates action button based on ownership
            }
            else {
                self.actionButton.setTitle("Sync", forState: UIControlState.Normal)
            }
        }
    }
    
    func databaseCheck(){
        if (TegKeychain.get(String(dbVersionString)) == nil) {
            ffdbLoaded = false
            TegKeychain.set(String(dbVersionString), value: "yes")
        }
        else {
            ffdbLoaded = true
        }
        
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            ffdbLoaded = false
            return
        }
        if let rscheck = database.intForQuery("SELECT COUNT(id) FROM patterns") {
            print("rscheck:\(rscheck)")
            if (UInt32(rscheck) > 0) {
                ffdbLoaded = true
            }
            else {
                ffdbLoaded = false
            }
        }
        else {
            ffdbLoaded = false
        }
        
        ///////////////////////////   code to load the database with data on first bootup or change
        if (ffdbLoaded==false){
            print("loading the entire thing")
            loadDatabase()
        }
    }
    
    func getOwnedFlashes(){
        //get any owned flashes from apple
        print("checking owned flashes with keychain and Apple")
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        //re-create patterns table
        database.executeUpdate("DROP TABLE ownedpatterns", withArgumentsInArray: nil)
        if !database.executeUpdate("create table ownedpatterns(id integer primary key autoincrement, storecode text, name text, patternid integer)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage()), probably already created")
        }
        
        //get the flash from keychain if one is owned
        if let result = TegKeychain.get(String(freeFlashString)) {
            print(result)
            addOwnedPattern(String(result))
        }
        
        //get the ones from apple
        if (SKPaymentQueue.canMakePayments()){
            print("payment queue check")
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        }
    }
    
}