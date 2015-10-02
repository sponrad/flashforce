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
var avgOffset: Double = 9999999
var cheering = false
var actionButtonStatus = "None"
var selectedStoreId: String = ""
var selectedPrice: String = ""
var oldBrightness: CGFloat = 0.5
var flashAble = false

let freeFlashString = "ffb001"       //keychain reference


//class ViewController: UIViewController, SKStoreProductViewControllerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
class ViewController: UIViewController, SKStoreProductViewControllerDelegate, SKProductsRequestDelegate {


    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var testCheerButton: UIBarButtonItem!
    @IBOutlet weak var outfitButton: UIButton!
    @IBOutlet weak var teamButton: UIButton!
    @IBOutlet weak var color1Label: UILabel!
    @IBOutlet weak var color2Label: UILabel!
    @IBOutlet weak var color3Label: UILabel!
    @IBOutlet weak var color4Label: UILabel!
    @IBOutlet weak var color5Label: UILabel!
    @IBOutlet weak var tapButton: UIButton!
    @IBOutlet weak var labelTopArrow: UILabel!
    @IBOutlet weak var labelBottomArrow: UILabel!
    @IBOutlet weak var labelMiddleArrow: UILabel!
    
    @IBOutlet weak var grayOverBrowse: UILabel!
    @IBOutlet weak var grayUnderBrowse: UILabel!
    @IBOutlet weak var grayUnderTeam: UILabel!
    @IBOutlet weak var grayOverFlash: UILabel!
    
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var flashForwardBoxes: UIImageView!
    
    var team = String()   // set from the secondbrowseviewcontroller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialStates()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"performSync", name:UIApplicationDidBecomeActiveNotification, object: nil) // adding observer for syncing
    
        checkOffsetAge() //change appearance of flash force icon based on offset age
        
        databaseCheck() // check database and load data if needed
        
        updateDisplay()  //update screen based on pattern and ownership
        
        setAverageOffset() //set the offset used while flashing
        
        if (isAppAlreadyLaunchedOnce() == false){
            firstTimeBoot()  //get owned IAPs and show tutorial images
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
                buyNonConsumable()
            default:
                print("do nothing")
        }
    }
    
    @IBAction func tapButtonTapped(sender: AnyObject) {
        performSync()
    }
    
    func performSync(){
        
        let url = NSBundle.mainBundle().URLForResource("longeranimated", withExtension: "gif")
        let imageData = NSData(contentsOfURL: url!)
        // Returns an animated UIImage
        self.flashForwardBoxes.image = UIImage.animatedImageWithData(imageData!)
        
        print("PERFORM SYNC resetting the offsets database")
        let qualityOfServiceClass = QOS_CLASS_USER_INTERACTIVE
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        var synced = false
        dispatch_async(backgroundQueue, {
            print("This is run on the background queue")
            
            ///////////////////////////   connect to the database
            let reachability = Reachability.reachabilityForInternetConnection()
            if reachability!.isReachable() {
                flashAble = true
                
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
                var averageOffset:[Double] = []
                self.getOffset()
                averageOffset.append(self.getOffset())
                averageOffset.append(self.getOffset())
                averageOffset.append(self.getOffset())
                averageOffset.append(self.getOffset())
                averageOffset.append(self.getOffset())
                averageOffset.append(self.getOffset())
                let average = averageOffset.reduce(0) { $0 + $1 } / Double(averageOffset.count)
                print( average )
                avgOffset = average
                database.executeUpdate("insert into offsets values (NULL, '\(String(stringInterpolationSegment: average))','\(String(stringInterpolationSegment: NSDate().timeIntervalSince1970))')", withArgumentsInArray: nil)
                
                database.close()
                synced = true
                
                }
                else {
                    print("not reachable")
                }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //print("This is run on the main queue, after the previous code in outer block")
                if (synced){
                    self.changeFlashImage()
                }
                else {
                    self.flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes-grayscale.png")
                }
                
            })
        })
    }
    
    func reachabilityChanged(notification: NSNotification){
        print("reachability changed")
        print(notification.description)
    }
    
    func changeFlashImage(){
        self.flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes.png")
    }
    
    func getOffset() -> Double {
        var offset : Double = 0
        let ct = NSDate().timeIntervalSince1970
        let serverEpochStr: String = parseJSON( getJSON("https://alignthebeat.appspot.com") )["epoch"] as! String
        let serverEpoch = (serverEpochStr as NSString).doubleValue
        let nct = NSDate().timeIntervalSince1970
        let ping = nct - ct
        //print("ping \(ping)")
        offset = serverEpoch - nct + ping
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
        self.actionButton.setTitle("Start Flash", forState: UIControlState.Normal)
        actionButtonStatus = "flash"
        
        addOwnedPattern(String(selectedStoreId), patternId: String(selectedId))
    }
    
    func buyNonConsumable(){
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
    
    func buyProduct(product: SKProduct){
        print("Sending the Payment Request to Apple");
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment);
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
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!)    {
        print("Received Payment Transaction Response from Apple");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .Purchased:
                    print("Product Purchased");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    addOwnedPattern(String(selectedStoreId), patternId: String(selectedId))
                    break;
                case .Failed:
                    print("Purchased Failed");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                    // case .Restored:
                    //[self restoreTransaction:transaction];
                default:
                    break;
                }
            }
        }
    }
    
    func addOwnedPattern(storeId: String, patternId: String){
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
        if let rs = database.executeQuery("SELECT * FROM patterns WHERE id='\(String(patternId))'", withArgumentsInArray: nil) {
            while rs.next() {
                name = rs.stringForColumn("name")
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
            var cheerId = ""
            //get the database code
            if let rs = database.executeQuery("SELECT * FROM patterns WHERE storecode='\(result)'", withArgumentsInArray: nil) {
                while rs.next() {
                    if (rs.stringForColumn("id") != ""){
                        cheerId = rs.stringForColumn("id")
                    }
                }
            }
            addOwnedPattern(String(result), patternId: cheerId)
            print("this fired")
        }
        
        //TODO: get any owned flashes from apple
        
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
        
        if !database.executeUpdate("create table patterns(id integer primary key autoincrement, storecode text, name text, category text, pattern text, timing text, price real, pattern1 text, pattern2 text, pattern3 text, pattern4 text, pattern5 text, alt1 text)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage())")
        }
        if !database.executeUpdate("create table offsets(id integer primary key autoincrement, offset real, timestamp real)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage()), probably already created")
        }
        if !database.executeUpdate("create table ownedpatterns(id integer primary key autoincrement, storecode text, name text, patternid integer)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage()), probably already created")
        }
        database.executeUpdate("DELETE FROM patterns", withArgumentsInArray: nil)
        //loop through initialData to build the database
        for record in StoreData.initialData {
            let pattern = record[5]  //stored in [5] through [9]...but may be empty
            let pattern1 = record[5]
            let pattern2 = record[6]
            let pattern3 = record[7]
            let pattern4 = record[8]
            let pattern5 = record[9]
            let timing = record[18]
            let price = record[4]
            database.executeUpdate("insert into patterns values (NULL, '\(record[0])', '\(record[2])', '\(record[1])', '\(pattern)', '\(timing)', \(price), '\(pattern1)', '\(pattern2)', '\(pattern3)', '\(pattern4)', '\(pattern5)', '\(record[3])')", withArgumentsInArray: nil)
        }
        
        
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
        testButton.hidden = true
        
        grayOverFlash.hidden = true
        grayUnderTeam.hidden = true
        
        UIScreen.mainScreen().brightness = oldBrightness
        
        flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes-grayscale.png")
        
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
                if ( (current - rs.doubleForColumn("timestamp")) < 3600.0){  //anything one hour or more recent
                    self.changeFlashImage()
                }
                else{
                    self.flashForwardBoxes.image = UIImage(named: "flash-forward-three-boxes-grayscale.png")
                    performSync()
                    flashAble = true  //temporary... should allow a flash even with a gray/no connection
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
        }
        else {
            if listOfOwnedPatterns().contains( String(selectedStoreId) ) {
                owned = true
            }
            else {
                //check ownership in apple store to see if owned
                if (SKPaymentQueue.canMakePayments()){
                    for transaction:SKPaymentTransaction in SKPaymentQueue.defaultQueue().transactions {
                        if transaction.payment.productIdentifier == String(selectedStoreId)
                        {
                            print("Non consumable Product is Purchased")
                            // Unlock Feature
                            owned = true
                            addOwnedPattern(String(selectedStoreId), patternId: String(selectedId))
                        }
                    }
                }
            }
        }
        //if owned: display the start flash button
        if (owned == true){
            self.actionButton.enabled = true
            self.actionButton.hidden = false
            self.actionButton.setTitle("Start Flash", forState: UIControlState.Normal)
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
                self.testCheerButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Buy $\(selectedPrice)", forState: UIControlState.Normal)
            } else {
                //if no, give option to grant this theme for free, with confirmation
                actionButtonStatus = "getfree"
                self.actionButton.enabled = true
                self.testCheerButton.enabled = true
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
        
        self.testButton.hidden = false
        
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
                
                selectedStoreId = rs.stringForColumn("storecode")
                selectedPrice = rs.stringForColumn("price")
                
                ///////////draw color boxes for selected flash
                var colors = [String]()
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
                let screenSize = self.view.bounds
                let boxSize = 38.0
                //let startingX = (Double(screenSize.width) / 2.0) - (boxSize * Double(colors.count)) + 10.0
                let startingX = 20.0
                for (index, color) in colors.enumerate() {
                    let imageSize = CGSize(width: boxSize, height: boxSize)
                    let xCoord = CGFloat((1.5 * Double(index) * boxSize) + startingX)
                    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: xCoord, y: CGFloat(screenSize.height - 130)), size: imageSize))
                    self.view.addSubview(imageView)
                    let image = drawBordered(imageSize, color: colorWithHexString(color))
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
            doOwnershipChecks() //updates display based on ownership
        }
    }
    
    func databaseCheck(){
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        // TODO add check for ffdbloaded, only load if there is a change in the db, compare rows of patterns maybe
        if let rscheck = database.intForQuery("SELECT COUNT(id) FROM patterns") {
            if (UInt32(rscheck) == UInt32(StoreData.initialData.count)) {
                ffdbLoaded = true
            }
        }
        ///////////////////////////   code to load the database with data on first bootup or change
        if (ffdbLoaded==false){
            loadDatabase()
        }
    }
    
}