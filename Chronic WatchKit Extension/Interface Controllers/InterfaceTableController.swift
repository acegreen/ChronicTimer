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
        
        NotificationCenter.default.addObserver(self, selector: #selector(WKInterfaceController.willActivate),name: NSNotification.Name("willActivate"), object: nil)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // Check for pro version purchase
        Constants.keychainProVersionString = Constants.keychain[Constants.proVersionKey]
        
        // Get Routines from database
        Constants.Routines = WatchDataAccess.sharedInstance.GetRoutines(predicate: nil)
        
        #if DEBUG
            
            loadTableData()
            
        #else
            
            if Functions.isProFeaturesUpgradePurchased() {
                
                loadTableData()
                
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
        
        guard Constants.Routines.count > 0 else {
            self.routineTable.setNumberOfRows(1, withRowType: "noRoutinesRow")
            return
        }
        
        self.routineTable.setNumberOfRows(Constants.Routines.count, withRowType: "routinesRow")
        
        for (index, item) in Constants.Routines.enumerated() {
            
            let row = self.routineTable.rowController(at: index) as! TableRowType
            
            row.routineRowLabel.setText(item.value(forKey: "name")! as? String)
            
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        
        if Constants.Routines.count != 0 {
            
            return Constants.Routines[rowIndex]
            
        }
        
        return nil
    }
    
    override func contextsForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> [Any]? {
        
        if Constants.Routines.count != 0 {
            
            return [Constants.Routines[rowIndex]]
            
        }
        
        return nil
    }
}
