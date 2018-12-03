//
//  TableViewController.swift
//  HerpMap
//
//  Created by Justin Sung on 12/2/18.
//  Copyright © 2018 Justin Sung. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    // Declare variable to which information from the main view controller will be stored
    var Entries = [herpEntry]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // Number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Number of rows per section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Entries.count
    }
    
    // Function to dynamically update information in entry log
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let herpCell = tableView.dequeueReusableCell(withIdentifier: "herpCell"
            , for: indexPath)
        
        // Set "title" part of cell to be the date and name of the herp
        herpCell.textLabel?.text = "\(Entries[indexPath.row].date as! String)   \(Entries[indexPath.row].herp as! String)"
        
        // Set "detail" part of cell to be the additional notes
        herpCell.detailTextLabel?.text = Entries[indexPath.row].notes as! String
        return herpCell
    }
}
