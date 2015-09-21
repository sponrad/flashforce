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
    var categories: [String] = []
    var filteredCategories: [String] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //searchController.searchResultsUpdater = self
        //searchController.hidesNavigationBarDuringPresentation = false
        //searchController.dimsBackgroundDuringPresentation = false
        //searchController.searchBar.sizeToFit()
        //self.tableView.tableHeaderView = searchController.searchBar
        
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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        //if searchController.active{
        //    return filteredCategories.count
       // }
        //else {
        return self.categories.count
        //}
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("categoryCell", forIndexPath: indexPath) 
        
        //if searchController.active {
        //    cell.textLabel!.text = self.filteredCategories[indexPath.row]
        //    cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
       // }
       // else{
            // Configure the cell
        cell.textLabel!.text = self.categories[indexPath.row]
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        //}


        return cell
    }
   
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        let i = self.browseTable.indexPathForSelectedRow?.row
        
        //searchController.active = false
        
        if let destinationVC = segue.destinationViewController as? SecondBrowseViewController{
            destinationVC.title = self.categories[i!]
            destinationVC.category = self.categories[i!]
        }

    }
   

}
