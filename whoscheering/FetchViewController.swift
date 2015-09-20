//
//  FetchViewController.swift
//  Flash Force
//
//  Created by Conrad on 7/25/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

//background task to update the time offets with the server

import UIKit

class FetchViewController: UIViewController {
    
    func fetch(completion: () -> Void) {
        print("Background task firing")
        
        ///////////////////////////   connect to the database
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        database.executeUpdate("DROP TABLE offsets", withArgumentsInArray: nil)
        
        
        if !database.executeUpdate("create table offsets(id integer primary key autoincrement, offset real)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage()), probably already created")
        }
        
        //load offsets
        var averageOffset:[Double] = []
        let reachability = Reachability.reachabilityForInternetConnection()
        if reachability!.isReachable() {
            
            getOffset()
            averageOffset.append(getOffset())
            averageOffset.append(getOffset())
            averageOffset.append(getOffset())
            let average = averageOffset.reduce(0) { $0 + $1 } / Double(averageOffset.count)
            database.executeUpdate("insert into offsets values (NULL, '\(String(stringInterpolationSegment: average))')", withArgumentsInArray: nil)
            
            
            //average all of the stored offsets
            var offsets:[Double] = []
            if let rs = database.executeQuery("SELECT * FROM offsets LIMIT 50", withArgumentsInArray: nil) {
                while rs.next() {
                    let offset = rs.doubleForColumn("offset")
                    offsets.append(offset)
                }
                avgOffset = offsets.reduce(0) { $0 + $1 } / Double(offsets.count)
                print(avgOffset)
            }
        }
        
        completion()
    }
    
    func getOffset() -> Double {
        var offset : Double = 0
        let ct = NSDate().timeIntervalSince1970    //seconds
        let serverEpochStr: String = parseJSON( getJSON("https://alignthebeat.appspot.com") )["epoch"] as! String
        let serverEpoch = (serverEpochStr as NSString).doubleValue
        let nct = NSDate().timeIntervalSince1970
        let ping = nct - ct
        offset = serverEpoch - nct + ping
        return offset
    }
    
    func getJSON(urlToRequest: String) -> NSData{
        return NSData(contentsOfURL: NSURL(string: urlToRequest)!)!
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
    
}
