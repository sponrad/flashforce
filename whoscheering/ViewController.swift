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


class ViewController: UIViewController, SKStoreProductViewControllerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {

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
    
    var team = String()   // set from the secondbrowseviewcontroller

    override func viewDidLoad() {
        super.viewDidLoad()
        cheering = false
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.hidesBackButton = false;
        self.outfitButton.enabled = false
        self.outfitButton.hidden = true
        self.teamButton.enabled = false
        self.teamButton.hidden = true
        self.teamButton.setTitle("", forState: UIControlState.Normal)
        //self.teamButton.titleLabel?.minimumScaleFactor = 0.01
        //self.teamButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.tapButton.setTitle("", forState: UIControlState.Normal)
        self.labelBottomArrow.hidden = true
        self.labelMiddleArrow.hidden = true
        
        UIScreen.mainScreen().brightness = oldBrightness
        
        //self.color1Label.backgroundColor = UIColor.whiteColor()

        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let path = documentsFolder.stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            println("Unable to open database")
            return
        }
        
        //draw design gray rectangles
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        
        //browse button underline
        let offset : CGFloat = 0   //offset from sides of screen
        let width = screenSize.width - (2 * offset)
        var boxSize = CGSize(width: width, height: 10)
        var boxView = UIImageView(frame: CGRect(origin: CGPoint(x: offset, y: screenSize.height - 320), size: boxSize))
        self.view.addSubview(boxView)
        var image = drawRect(boxSize, color: colorWithHexString("EEEEEE"))
        boxView.image = image
        
        //browse button overline
        boxSize = CGSize(width: width, height: 10)
        boxView = UIImageView(frame: CGRect(origin: CGPoint(x: offset, y: screenSize.height - 405), size: boxSize))
        self.view.addSubview(boxView)
        image = drawRect(boxSize, color: colorWithHexString("EEEEEE"))
        boxView.image = image
        
        //there is a team selected (will never fire on first boot)
        if (self.team != ""){
            self.teamButton.hidden = false
            self.teamButton.enabled = true
            
            //teambutton underline
            boxSize = CGSize(width: width, height: 10)
            boxView = UIImageView(frame: CGRect(origin: CGPoint(x: offset, y: screenSize.height - 230), size: boxSize))
            self.view.addSubview(boxView)
            image = drawRect(boxSize, color: colorWithHexString("EEEEEE"))
            boxView.image = image
            
            //draw the rect over the flash button
            boxSize = CGSize(width: screenSize.width, height: 10)
            boxView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: screenSize.height - 78), size: boxSize))
            self.view.addSubview(boxView)
            var imagef = drawRect(boxSize, color: colorWithHexString("EEEEEE"))
            boxView.image = imagef
            self.labelMiddleArrow.hidden = false
            
            //check if there are alternates for the selected team (depends of flash name being somewhat unique)
            if let count = database.intForQuery("SELECT COUNT(name) FROM cheers WHERE name='\(self.team)'") {
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
                println("select failed: \(database.lastErrorMessage())")
            }
            
            //display correct information
            if let rs = database.executeQuery("SELECT * FROM cheers WHERE id=\(String(selectedId))", withArgumentsInArray: nil) {
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
                    let boxSize = 38.0
                    //let startingX = (Double(screenSize.width) / 2.0) - (boxSize * Double(colors.count)) + 10.0
                    let startingX = 20.0
                    for (index, color) in enumerate(colors) {
                        var imageSize = CGSize(width: boxSize, height: boxSize)
                        let xCoord = CGFloat((1.5 * Double(index) * boxSize) + startingX)
                        var imageView = UIImageView(frame: CGRect(origin: CGPoint(x: xCoord, y: CGFloat(screenSize.height - 130)), size: imageSize))
                        self.view.addSubview(imageView)
                        var image = drawBordered(imageSize, color: colorWithHexString(color))
                        imageView.image = image
                    }

                }
            } else {
                println("select failed: \(database.lastErrorMessage())")
            }
        }

        ///////////////////////////   flash button logic, also should never fire on first boot
        if (self.team == ""){
            self.actionButton.enabled = false
            self.actionButton.alpha = 0.3
            self.actionButton.hidden = true
            self.actionButton.enabled = false
        }
        else {
            //check if they own the product or not
            var owned = false  //check against app store
                      
            //check ownership against keychain
            if (TegKeychain.get("freecheer") != nil){
                if TegKeychain.get("freecheer")! == selectedStoreId {
                    owned = true
                }
            }
            else {
                //TODO add a check for local db before the apple check
                //check ownership in apple store to see if owned
                if (SKPaymentQueue.canMakePayments()){
                    for transaction:SKPaymentTransaction in SKPaymentQueue.defaultQueue().transactions as! [SKPaymentTransaction] {
                        if transaction.payment.productIdentifier == String(selectedStoreId)
                        {
                            println("Non consumable Product is Purchased")
                            // Unlock Feature
                            owned = true
                            //TODO: add this to a local table in the database of owned products
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
                if var result = TegKeychain.get("freecheer") {   //this is set when the flash button is tapped
                    println("In Keychain: \(result)")
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
        
        
        // TODO add check for ffdbloaded, only load if there is a change in the db, compare rows of cheers maybe
        // should improve load time a lot
        
        ///////////////////////////   code to load the database with data on first bootup
        if (ffdbLoaded==false){
            database.executeUpdate("DROP TABLE cheers", withArgumentsInArray: nil)
            //database.executeUpdate("DROP TABLE offsets", withArgumentsInArray: nil)
            
            if !database.executeUpdate("create table cheers(id integer primary key autoincrement, storecode text, name text, category text, pattern text, timing text, price real, pattern1 text, pattern2 text, pattern3 text, pattern4 text, pattern5 text, alt1 text)", withArgumentsInArray: nil) {
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
                let timing = record[18]
                let price = record[4]
                database.executeUpdate("insert into cheers values (NULL, '\(record[0])', '\(record[2])', '\(record[1])', '\(pattern)', '\(timing)', \(price), '\(pattern1)', '\(pattern2)', '\(pattern3)', '\(pattern4)', '\(pattern5)', '\(record[3])')", withArgumentsInArray: nil)
            }
            
            let reachability = Reachability.reachabilityForInternetConnection()
            if reachability.isReachable() {
                
                database.executeUpdate("DROP TABLE offsets", withArgumentsInArray: nil)
                
                if !database.executeUpdate("create table offsets(id integer primary key autoincrement, offset real)", withArgumentsInArray: nil) {
                    println("create table failed: \(database.lastErrorMessage()), probably already created")
                }
                
                //load offsets
                var averageOffset:[Double] = []
                getOffset()
                averageOffset.append(getOffset())
                averageOffset.append(getOffset())
                averageOffset.append(getOffset())
                let average = averageOffset.reduce(0) { $0 + $1 } / Double(averageOffset.count)
                println( average )
                database.executeUpdate("insert into offsets values (NULL, '\(String(stringInterpolationSegment: average))')", withArgumentsInArray: nil)
                flashAble = true
            }
            else {
                println("not reachable")
            }
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
            reachability.startNotifier()
            
            //average all of the stored offsets
            var offsets:[Double] = []
            if let rs = database.executeQuery("SELECT * FROM offsets LIMIT 50", withArgumentsInArray: nil) {
                while rs.next() {
                    var nRows = rs.intForColumnIndex(0)
                    if (nRows > 0){
                        flashAble = true   //allow flash if there is at least one offset stored
                    }
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
        switch actionButtonStatus {
            case "flash":
                if flashAble {
                    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    var setViewController = mainStoryboard.instantiateViewControllerWithIdentifier("cheer") as! UIViewController
                    navigationController?.pushViewController(setViewController, animated: true)
                }
                else {
                    println("do not flash if no offsets stored")
                    var alert = UIAlertController(title: "Unable to Flash", message: "Please connect to the internet and restart Flash Force", preferredStyle: UIAlertControllerStyle.Alert)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: purchaseFreeFlash ))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            case "getfree":
                var alert = UIAlertController(title: "Free Flash", message: "Do you want to use your one free flash for this product?", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: purchaseFreeFlash ))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            case "buy":
                buyNonConsumable()
                /*var alert = UIAlertController(title: "Buy Flash !!!NOT DONE YET!!!", message: "Buy this flash for $\(selectedPrice)?", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Buy", style: UIAlertActionStyle.Default, handler: buyNonConsumable ))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)*/
            default:
                println("do nothing")
        }
    }
    
    @IBAction func tapButtonTapped(sender: AnyObject) {
        //reset the keychain
        //TegKeychain.delete("freecheer")
        println("resetting the offsets database")
        // reset the offsets database.
        ///////////////////////////   connect to the database
        let reachability = Reachability.reachabilityForInternetConnection()
        if reachability.isReachable() {
            flashAble = true
            
            let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
            let path = documentsFolder.stringByAppendingPathComponent("ff.db")
            let database = FMDatabase(path: path)
            if !database.open() {
                println("Unable to open database")
                return
            }
            database.executeUpdate("DROP TABLE offsets", withArgumentsInArray: nil)
            
            
            if !database.executeUpdate("create table offsets(id integer primary key autoincrement, offset real)", withArgumentsInArray: nil) {
                println("create table failed: \(database.lastErrorMessage()), probably already created")
            }
            
            //load offsets
            var averageOffset:[Double] = []
            getOffset()
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
        }
        else {
            println("not reachable")
        }
        
    }
    
    func reachabilityChanged(notification: NSNotification){
        println("reachability changed")
        println(notification.description)
    }
    
    func getOffset() -> Double {
        var offset : Double = 0
        let ct = NSDate().timeIntervalSince1970
        let serverEpochStr: String = parseJSON( getJSON("http://alignthebeat.appspot.com") )["epoch"] as! String
        let serverEpoch = (serverEpochStr as NSString).doubleValue
        let nct = NSDate().timeIntervalSince1970
        let ping = nct - ct
        println("ping \(ping)")
        offset = serverEpoch - nct + ping
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
    
    func drawRect(size: CGSize, color: UIColor) -> UIImage {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zeroPoint, size: size)
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
        let bounds = CGRect(origin: CGPoint.zeroPoint, size: size)
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
    
    //purchase a flash for free, set the token, and change the action button
    func purchaseFreeFlash (alert: UIAlertAction!){
        TegKeychain.set("freecheer", value: selectedStoreId)
        self.actionButton.enabled = true
        self.actionButton.hidden = false
        self.actionButton.setTitle("Start Flash", forState: UIControlState.Normal)
        actionButtonStatus = "flash"
    }
    
    func buyNonConsumable(){
        println("About to fetch the products");
        // We check that we are allow to make the purchase.
        if (SKPaymentQueue.canMakePayments())
        {
            var productID:NSSet = NSSet(object: String(selectedStoreId));
            var productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as Set<NSObject>);
            productsRequest.delegate = self;
            productsRequest.start();
            println("Fetching Products");
        }else{
            println("can't make purchases");
        }
    }
    
    func buyProduct(product: SKProduct){
        println("Sending the Payment Request to Apple");
        var payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment);
    }
    
    func productsRequest (request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        println("got the request from Apple")
        var count : Int = response.products.count
        if (count>0) {
            var validProducts = response.products
            var validProduct: SKProduct = response.products[0] as! SKProduct
            if (validProduct.productIdentifier == String(selectedStoreId)) {
                println(validProduct.localizedTitle)
                println(validProduct.localizedDescription)
                println(validProduct.price)
                buyProduct(validProduct);
            } else {
                println(validProduct.productIdentifier)
            }
        } else {
            println("nothing")
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!)    {
        println("Received Payment Transaction Response from Apple");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .Purchased:
                    println("Product Purchased");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                case .Failed:
                    println("Purchased Failed");
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
    

}