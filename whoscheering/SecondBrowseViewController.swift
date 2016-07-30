//
//  SecondBrowseViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/25/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit
import StoreKit

class SecondBrowseViewController: UITableViewController, UISearchResultsUpdating, SKPaymentTransactionObserver {

    @IBOutlet weak var restoreButton: UIBarButtonItem!
    @IBOutlet var drillTable: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    var category = String()  //set by previous view
    var details = [[Any]]()
    var filteredDetails = [[Any]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)

        self.restoreButton.enabled = false

        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar
        
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        
        if (self.category == ""){  //this fires if user is changing team after selecting one previously
            //print("Not set")
            if let rs1 = database.executeQuery("SELECT category FROM patterns WHERE id='\(selectedId)'", withArgumentsInArray: nil) {
                while rs1.next() {
                    self.category = rs1.stringForColumn("category")
                }
            } else {
                print("select failed: \(database.lastErrorMessage())")
            }
        }
        
        if (self.category == "My Flashes"){
            self.restoreButton.enabled = true
            //TODO: pull from keystore would be best...
            if let rs = database.executeQuery("SELECT name, id FROM patterns WHERE storecode IN (SELECT storecode FROM ownedpatterns) GROUP BY name ORDER BY name", withArgumentsInArray: nil) {
                while rs.next() {
                    self.details.append([rs.stringForColumn("name"), rs.intForColumn("id")])
                }
            } else {
                print("select failed: \(database.lastErrorMessage())")
            }

        }
        else {
            if let rs = database.executeQuery("SELECT name, id FROM patterns WHERE category='\(self.category)' AND alt1='Home' UNION  SELECT name, id FROM patterns WHERE category='\(self.category)' AND name NOT IN (SELECT name FROM patterns WHERE category='\(self.category)' AND alt1='Home') GROUP BY name ORDER BY name", withArgumentsInArray: nil) {

                while rs.next() {
                    self.details.append([rs.stringForColumn("name"), rs.intForColumn("id")])
                }
            } else {
                print("select failed: \(database.lastErrorMessage())")
            }
        }
        
        self.filteredDetails = self.details
        database.close()
    }
    
    override func viewWillDisappear(animated: Bool) {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
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
                let found = String(stringInterpolationSegment: s[0]).rangeOfString(target!, options: options)
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
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {      
        if self.searchController.active{
            return filteredDetails.count
        }
        else {
            return details.count
        }

    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("drillCell", forIndexPath: indexPath)

        if searchController.active{
            cell.textLabel!.text = String(stringInterpolationSegment: self.filteredDetails[indexPath.row][0])
        }
        else {
            cell.textLabel!.text = String(stringInterpolationSegment: self.details[indexPath.row][0])
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.category.rangeOfString("Schools") != nil {
            performSegueWithIdentifier("browsetoalternate", sender: self)
        }
        else {
            performSegueWithIdentifier("browsetohome", sender: self)
        }
    }


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let selectedCheer = self.drillTable.indexPathForSelectedRow?.row
        //searchController.active = false
        //TODO: if in the school category, direct to the alternate View einstead of ViewController.
        
        if self.category.rangeOfString("Schools") != nil {
            print ("in school category check fired")
            
            if let svc = segue.destinationViewController as? AlternateViewController {
                svc.name = ""
                selectedId = (self.filteredDetails[selectedCheer!][1] as? Int32)!
            }

        }
        else {
            if let homeVC = segue.destinationViewController as? ViewController{
                if self.searchController.active {
                    print("yeah this is firing")
                    homeVC.team = String(stringInterpolationSegment: self.filteredDetails[selectedCheer!][0])
                    selectedId = (self.filteredDetails[selectedCheer!][1] as? Int32)!
                    searchController.active = false
                }
                else{
                    print("NO THIS ONE IS FIRING")
                    homeVC.team = String(stringInterpolationSegment: self.details[selectedCheer!][0])
                    selectedId = (self.filteredDetails[selectedCheer!][1] as? Int32)!
                }
            }
        }
    }
    
    @IBAction func restoreButtonTapped(sender: AnyObject) {
        print("restore tapped")
        
        //re-create owned patterns table
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        database.executeUpdate("DROP TABLE ownedpatterns", withArgumentsInArray: nil)
        if !database.executeUpdate("create table ownedpatterns(id integer primary key autoincrement, storecode text, name text, patternid integer)", withArgumentsInArray: nil) {
            print("create table failed: \(database.lastErrorMessage()), probably already created")
        }
        
        ViewController().getFreeFlash()
        self.drillTable.reloadData()
        
        self.restoreButton.title = "Restoring..."
        
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        
        //self.restoreButton.title = "Restore"
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
        print("Received Payment Transaction Response from Apple secondviewcontroller");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .Purchased, .Restored:
                    print("Product Purchased/Restored");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as! SKPaymentTransaction)
                    ViewController().addOwnedPattern(String(transaction.payment.productIdentifier))
                    //doOwnershipChecks()
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
        
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let path = NSString(string: documentsFolder).stringByAppendingPathComponent("ff.db")
        let database = FMDatabase(path: path)
        if !database.open() {
            print("Unable to open database")
            return
        }
        if let rs = database.executeQuery("SELECT name, id FROM patterns WHERE storecode IN (SELECT storecode FROM ownedpatterns) GROUP BY name ORDER BY name", withArgumentsInArray: nil) {
            while rs.next() {
                self.details.append([rs.stringForColumn("name"), rs.intForColumn("id")])
            }
        } else {
            print("select failed: \(database.lastErrorMessage())")
        }
        
        //redraw/restore the table
        self.drillTable.reloadData()
        
        self.restoreButton.title = "Restore"
    }

}
