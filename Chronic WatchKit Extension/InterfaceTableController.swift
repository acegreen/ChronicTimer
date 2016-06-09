//
//  InterfaceTableController.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-09.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceTableController: WKInterfaceController {
    
    @IBOutlet var routineTable: WKInterfaceTable!

    override init() {
        
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WKInterfaceController.willActivate),name:"willActivate", object: nil)
        
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
    }

    override func willActivate() {
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // Check for pro version purchase
        keychainProVersionString = keychain[proVersionKey]
        
        if proFeaturesUpgradePurchased() {
        
            // Get Routines from database
            Routines = WatchDataAccess.sharedInstance.GetRoutines(nil) as! [RoutineModel]
            
            if Routines.count != 0 {
                
                loadTableData()
                
            } else {
                
                self.routineTable.setNumberOfRows(1, withRowType: "noRoutinesRow")
            }
        
        } else {
            
            self.routineTable.setNumberOfRows(1, withRowType: "noProVersionRow")
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadTableData() {
        
        self.routineTable.setNumberOfRows(Routines.count, withRowType: "routinesRow")
        
        for (index, item) in Routines.enumerate() {
            
            let row = self.routineTable.rowControllerAtIndex(index) as! TableRowType
            
            row.routineRowLabel.setText(item.valueForKey("name")! as? String)
            
        }
    }

    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        
        if Routines.count != 0 {
            
            return Routines[rowIndex]
            
        }
        
        return nil
    }
    
    override func contextsForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> [AnyObject]? {
        
        if Routines.count != 0 {
            
            return [Routines[rowIndex]]
            
        }
        
        return nil
        
    }
}
