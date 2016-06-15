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
        
        NotificationCenter.default().addObserver(self, selector: #selector(WKInterfaceController.willActivate),name:"willActivate", object: nil)
        
    }
    
    override func awake(withContext context: AnyObject?) {
        super.awake(withContext: context)
        
    }

    override func willActivate() {
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // Check for pro version purchase
        keychainProVersionString = keychain[proVersionKey]
        
        #if DEBUG
            // Get Routines from database
            Routines = WatchDataAccess.sharedInstance.GetRoutines(predicate: nil)
            
            if Routines.count != 0 {
                
                loadTableData()
                
            } else {
                
                self.routineTable.setNumberOfRows(1, withRowType: "noRoutinesRow")
            }
            
        #else
            if proFeaturesUpgradePurchased() {
                
                // Get Routines from database
                Routines = WatchDataAccess.sharedInstance.GetRoutines(predicate: nil)
                
                if Routines.count != 0 {
                    
                    loadTableData()
                    
                } else {
                    
                    self.routineTable.setNumberOfRows(1, withRowType: "noRoutinesRow")
                }
                
            } else {
                
                self.routineTable.setNumberOfRows(1, withRowType: "noProVersionRow")
            }
        #endif
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadTableData() {
        
        self.routineTable.setNumberOfRows(Routines.count, withRowType: "routinesRow")
        
        for (index, item) in Routines.enumerated() {
            
            let row = self.routineTable.rowController(at: index) as! TableRowType
            
            row.routineRowLabel.setText(item.value(forKey: "name")! as? String)
            
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        
        if Routines.count != 0 {
            
            return Routines[rowIndex]
            
        }
        
        return nil
    }
    
    override func contextsForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> [AnyObject]? {
        
        if Routines.count != 0 {
            
            return [Routines[rowIndex]]
            
        }
        
        return nil
        
    }
}
