//
//  InterfaceTableController.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-09.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import WatchKit
import ChronicKit
import Foundation

class InterfaceTableController: WKInterfaceController {
    
    var routines = [RoutineModel]()
    
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
        do {
            
            self.routines = try WatchDataAccess.sharedInstance.fetchRoutines(with: nil)
        
            #if DEBUG
                
                loadTableData()
                
            #else
                
                if Functions.isProFeaturesUpgradePurchased() {
                    
                    loadTableData()
                    
                } else {
                    
                    self.routineTable.setNumberOfRows(1, withRowType: "noProVersionRow")
                }
                
            #endif
            
        } catch {
            // TO-DO: HANDLE ERROR
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadTableData() {
        
        guard routines.count > 0 else {
            self.routineTable.setNumberOfRows(1, withRowType: "noRoutinesRow")
            return
        }
        
        self.routineTable.setNumberOfRows(routines.count, withRowType: "routinesRow")
        
        for (index, item) in routines.enumerated() {
            
            let row = self.routineTable.rowController(at: index) as! TableRowType
            
            row.routineRowLabel.setText(item.value(forKey: "name")! as? String)
            
        }
    }

    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        
        if routines.count != 0 {
            
            return routines[rowIndex]
            
        }
        
        return nil
    }
    
    override func contextsForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> [Any]? {
        
        if routines.count != 0 {
            
            return [routines[rowIndex]]
            
        }
        
        return nil
    }
}
