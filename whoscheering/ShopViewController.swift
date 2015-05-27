//
//  ShopViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/21/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

class ShopViewController: UIViewController {

    @IBOutlet weak var shopCategory: UITableView!
    
    let tableData = StoreData.categories
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        return self.tableData.count;
    }

    func tableView(tableView: UITableView!,
        cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        let cell:UITableViewCell = UITableViewCell(style:UITableViewCellStyle.Default, reuseIdentifier:"cell")
        cell.textLabel?.text = tableData[indexPath.row]
        
        return cell
    }

}
