//
//  RoutineTypeViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-25.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import QuartzCore

class RoutineTypeViewController: UIViewController, RoutineDelegate {
    
    var delegate: RoutineDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didCreateRoutine(_ routine: RoutineModel, isNew: Bool) {
        self.delegate?.didCreateRoutine(routine, isNew: isNew)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "AddCircuitRoutineSegueIdentifier" {
            
            let circuitRoutineTableViewController = segue.destination as! CircuitRoutineTableViewController
            circuitRoutineTableViewController.delegate = self
            
        } else if segue.identifier == "AddCustomRoutineSegueIdentifier" {
            
            let customRoutineTableViewController = segue.destination as! CustomRoutineTableViewController
            customRoutineTableViewController.delegate = self
        }
    }
}
