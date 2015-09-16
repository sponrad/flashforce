//
//  SecondBrowseViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/25/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

class SecondBrowseViewController: UITableViewController, UISearchResultsUpdating {
    

    @IBOutlet var drillTable: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    var category = String()  //set by previous view
    var details = [[Any]]()
    var filteredDetails = [[Any]]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar
        
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let path = documentsFolder.stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            println("Unable to open database")
            return
        }
        
        if (self.category == ""){  //this fires if use is changing team after selecting one previously
            //println("Not set")
            if let rs1 = database.executeQuery("SELECT category FROM cheers WHERE id='\(selectedId)'", withArgumentsInArray: nil) {
                while rs1.next() {
                    self.category = rs1.stringForColumn("category")
                }
            } else {
                println("select failed: \(database.lastErrorMessage())")
            }
        }
        
        if let rs = database.executeQuery("SELECT name, id FROM cheers WHERE category='\(self.category)' GROUP BY name ORDER BY name", withArgumentsInArray: nil) {
            while rs.next() {
                self.details.append([rs.stringForColumn("name"), rs.intForColumn("id")])
            }
        } else {
            println("select failed: \(database.lastErrorMessage())")
        }
        
        self.filteredDetails = self.details
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let sb = searchController.searchBar
        let target = sb.text
        if (target == ""){
            self.filteredDetails = self.details
        }
        else {
            self.filteredDetails = self.details.filter {
                s in
                let options = NSStringCompareOptions.CaseInsensitiveSearch
                let found = String(stringInterpolationSegment: s[0]).rangeOfString(target, options: options)
                return (found != nil)
            }
        }
        self.tableView.reloadData()
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
        if self.searchController.active{
            return filteredDetails.count
        }
        else {
            return details.count
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("drillCell", forIndexPath: indexPath) as! UITableViewCell

        if searchController.active{
            cell.textLabel!.text = String(stringInterpolationSegment: self.filteredDetails[indexPath.row][0])
        }
        else {
            cell.textLabel!.text = String(stringInterpolationSegment: self.details[indexPath.row][0])
        }
        
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
        
        //searchController.active = false
        
        
        if let homeVC = segue.destinationViewController as? ViewController{
            if self.searchController.active {
                println("yeah this is firing")
                homeVC.team = String(stringInterpolationSegment: self.filteredDetails[selectedCheer!][0])
                selectedId = (self.filteredDetails[selectedCheer!][1] as? Int32)!
                searchController.active = false
            }
            else{
                println("NO THIS ONE IS FIRING")
                homeVC.team = String(stringInterpolationSegment: self.details[selectedCheer!][0])
                selectedId = (self.filteredDetails[selectedCheer!][1] as? Int32)!
            }

        }
    }


}
