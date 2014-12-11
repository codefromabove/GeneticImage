//
//  PropertiestViewController.swift
//  GeneticImage
//
//  Created by Dzianis Lebedzeu on 12/9/14.
//  Copyright (c) 2014 Home. All rights reserved.
//

import UIKit


class PropertiestViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Configuration"
        } else if section == 1 {
            return "Drawing"
        } else {
            return "Info"
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sliderCell") as UITableViewCell
        return cell
    }
}
