//
//  AlternateViewController.swift
//  Flash Force
//
//  Created by Conrad on 7/22/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

class AlternateViewController: UITableViewController {
    
    @IBOutlet var drillTable: UITableView!
    
    var details = [[Any]]()
    var groupid = ""
    var name = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        if let rs2 = database.executeQuery("SELECT groupid FROM patterns WHERE id='\(selectedId)'", withArgumentsInArray: nil) {
            while rs2.next() {
                self.groupid = rs2.stringForColumn("groupid")
            }
        } else {
            print("select failed: \(database.lastErrorMessage())")
        }
        
        if let rs = database.executeQuery("SELECT alt1, id, name FROM patterns WHERE groupid='\(self.groupid)' ORDER BY alt1", withArgumentsInArray: nil) {
            while rs.next() {
                self.name = rs.stringForColumn("name")
                var text: String = ""
                if rs.stringForColumn("alt1").isEmpty{
                    text = self.name+" Home"
                } else {
                    text = String(stringInterpolationSegment: rs.stringForColumn("alt1"))
                }
                self.details.append([text, rs.intForColumn("id")])
            }
        } else {
            print("select failed: \(database.lastErrorMessage())")
        }
        database.close()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.details.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("drillCell", forIndexPath: indexPath)
        
        // Configure the cell...
        cell.textLabel!.text = String(stringInterpolationSegment: self.details[indexPath.row][0])
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let selectedCheer = self.drillTable.indexPathForSelectedRow!.row
        
        if let homeVC = segue.destinationViewController as? ViewController{
            homeVC.team = self.name
            selectedId = (self.details[selectedCheer][1] as? Int32)!
        }
    }
    
    
}

