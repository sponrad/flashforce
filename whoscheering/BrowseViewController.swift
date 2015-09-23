//
//  BrowseViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/25/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

class BrowseViewController: UITableViewController {
    
    @IBOutlet var browseTable: UITableView!
    
    //let searchController = UISearchController(searchResultsController: nil)
    var categories: [String] = ["My Flashes"]
    var filteredCategories: [String] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        if let rs = database.executeQuery("SELECT DISTINCT category FROM patterns ORDER BY category", withArgumentsInArray: nil) {
            while rs.next() {
                self.categories.append(rs.stringForColumn("category"))
            }
        } else {
            print("select failed: \(database.lastErrorMessage())")
        }
        
        browseTable.delegate = self
        browseTable.dataSource = self

        database.close()
    }
    
    /*
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let sb = searchController.searchBar
        let target = sb.text
        if (target == ""){
            self.filteredCategories = self.categories
        }
        else {
            self.filteredCategories = self.categories.filter {
                s in
                let options = NSStringCompareOptions.CaseInsensitiveSearch
                let found = s.rangeOfString(target, options: options)
                return (found != nil)
            }
        }
        self.tableView.reloadData()
    }*/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("categoryCell", forIndexPath: indexPath) 

        cell.textLabel!.text = self.categories[indexPath.row]
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        return cell
    }
   
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let i = self.browseTable.indexPathForSelectedRow?.row
        
        if let destinationVC = segue.destinationViewController as? SecondBrowseViewController{
            destinationVC.title = self.categories[i!]
            destinationVC.category = self.categories[i!]
        }
    }
}
