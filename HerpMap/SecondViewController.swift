//
//  SecondViewController.swift
//  Salamanders
//
//  Created by Justin Sung on 12/1/18.
//  Copyright © 2018 Justin Sung. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let log = ["Scarlet King", "Spotted", "Marbled"]
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return(log.count)
    }
    

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let herpEntry = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "herpEntry" )
        herpEntry.textLabel?.text = log[indexPath.row]
        
        return(herpEntry)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
