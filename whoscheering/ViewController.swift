//
//  ViewController.swift
//  whoscheering
//
//  Created by Conrad on 5/21/15.
//  Copyright (c) 2015 Conrad. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var outfitLabel: UILabel!
    @IBOutlet weak var startCheeringButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!
    
    var team = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.teamLabel.text = self.team
        self.outfitLabel.text = ""
        
        self.startCheeringButton.layer.borderColor = UIColor.blackColor().CGColor
        self.startCheeringButton.layer.borderWidth = 5
        
        if (self.team == ""){
            self.startCheeringButton.enabled = false
            self.startCheeringButton.alpha = 0.3
            self.actionButton.hidden = true
        }
        else {
            //check if they own the theme or not
            //if owned: display the start cheer button
            //if not owned:
            //check Keychain for if first theme has been purchased
            //TegKeychain.clear()
            if var result = TegKeychain.get("visitedcheer") {   //this is currently set in CheerViewController
                println("In Keychain: \(result)")
           ; } else {
                println("no value in keychain")
            }
            //if yes then display the normal IAP button
            //if no, give option to grant this theme for free, with confirmation
            
            if contains(["Duke", "Fireworks", "Kings"], self.team){
                //example not owned
                self.startCheeringButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Buy Cheer $x.xx", forState: .Normal)
            }
            else{
                self.startCheeringButton.enabled = true
                self.actionButton.hidden = false
                self.actionButton.setTitle("Start Cheering", forState: .Normal)
                self.outfitLabel.text = "Outfits"
            }
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
        var alert = UIAlertController(title: "Future functionality", message: "Buy this cheer, get first free, or start cheering if owned", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
        //Buy the cheer
        //OR Start cheering
    }
}