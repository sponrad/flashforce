//
//  SecondBrowseViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/25/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

class SecondBrowseViewController: UITableViewController {
    

    @IBOutlet var drillTable: UITableView!
    
    var category = String()  //set by previous view
    var details = [[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let path = documentsFolder.stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            println("Unable to open database")
            return
        }
        
        if let rs = database.executeQuery("SELECT name, id FROM cheers WHERE category='\(self.category)' GROUP BY name ORDER BY name", withArgumentsInArray: nil) {
            while rs.next() {
                self.details.append([rs.stringForColumn("name"), rs.intForColumn("id")])
            }
        } else {
            println("select failed: \(database.lastErrorMessage())")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.details.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("drillCell", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        cell.textLabel!.text = String(stringInterpolationSegment: self.details[indexPath.row][0])

        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view
        var selectedCheer = self.drillTable.indexPathForSelectedRow()?.row
        
        if let homeVC = segue.destinationViewController as? ViewController{
            homeVC.team = String(stringInterpolationSegment: self.details[selectedCheer!][0])
            selectedId = (self.details[selectedCheer!][1] as? Int32)!
        }
    }


}
