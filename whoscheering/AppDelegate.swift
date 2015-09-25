//
//  AppDelegate.swift
//  whoscheering
//
//  Created by Conrad on 5/21/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        oldBrightness = UIScreen.mainScreen().brightness
        
        // Override point for customization after application launch.
        //UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(43200)
        //UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        return true
        
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        UIScreen.mainScreen().brightness = oldBrightness
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            print("This is run on the background queue")
            
            
            if (!cheering){
                // sync if internet
                let reachability = Reachability.reachabilityForInternetConnection()
                if reachability!.isReachable() {
                    ///////////////////////////   connect to the database
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
                    let average = averageOffset.reduce(0) { $0 + $1 } / Double(averageOffset.count)
                    print( average )
                    avgOffset = average
                    database.executeUpdate("insert into offsets values (NULL, '\(String(stringInterpolationSegment: average))','\(String(stringInterpolationSegment: NSDate().timeIntervalSince1970))')", withArgumentsInArray: nil)
                    flashAble = true
                    print("synced to enter foreground")
                    database.close()
                }
                else {
                    print("not reachable")
                }
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //print("This is run on the main queue, after the previous code in outer block")
            })
        })
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // Support for background fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        let fetchView = FetchViewController()
        fetchView.fetch{ completionHandler(.NewData) }
    }
    
    func getOffset() -> Double {
        var offset : Double = 0
        let ct = NSDate().timeIntervalSince1970
        let serverEpochStr: String = parseJSON( getJSON("https://alignthebeat.appspot.com") )["epoch"] as! String
        let serverEpoch = (serverEpochStr as NSString).doubleValue
        let nct = NSDate().timeIntervalSince1970
        let ping = nct - ct
        print("ping \(ping)")
        offset = serverEpoch - nct + ping
        return offset
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
}

