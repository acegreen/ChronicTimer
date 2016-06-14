//
//  RoutinesTableViewController.swift
//  Chronic
//
//  Created by Ahmed E on 10/03/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import QuartzCore
import DZNEmptyDataSet
import LaunchKit

class RoutinesTableViewController: UITableViewController, UIPopoverControllerDelegate {

    @IBAction func runnerButtonPressed(_ sender: AnyObject) {
        
        guard proFeaturesUpgradePurchased() || ((LaunchKit.sharedInstance().currentUser?.isSuper() == true) && !removeAdsUpgradePurchased()) else {
            IAPHelper.sharedInstance.selectProduct(proVersionKey)
            return
        }
            
        if Routines != nil {
            
            deselectSelectedRoutine()
        }
        
        let timerViewController = mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
        timerViewController.initializeRunner()
        
        appDel.window?.rootViewController?.present(timerViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Meant to remove the cell separators on empty table
        self.tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        if !Routines.isEmpty {
            reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reloadData() {
        
        self.tableView.reloadData()
    }
    
    // MARK: -TableView Functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return Routines.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RoutineCell
        
        if Routines.count != 0 {
            
                let routine = Routines[(indexPath as NSIndexPath).row]
                cell.configure(with: routine)
                
//                if indexPath.row == selectedRow {
//                    
//                    cell.accessoryType = .Checkmark
//                    
//                } else {
//                    
//                    cell.accessoryType = .None
//                }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        if Routines.count != 0 {
            
            setSelectedRoutine(Routines[(indexPath as NSIndexPath).row], completion: { (result) -> Void in
                
                let timerViewController = mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
                timerViewController.initializeRoutine(with: Routines[(indexPath as NSIndexPath).row])
                
                appDel.window?.rootViewController?.present(timerViewController, animated: true, completion: nil)
            })
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: true)
        
        if !editing {
            
            var i = Routines.count
            
            for routine in Routines {
                
                routine.setValue(i--, forKey: "tableDisplayOrder")
            
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let selectedRoutine = Routines[(indexPath as NSIndexPath).row]
        
        let editAction = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) -> Void in
            
            if selectedRoutine.type == "Circuit" {
                
                self.performSegue(withIdentifier: "EditCircuitRoutineSegueIdentifier", sender: selectedRoutine)
                
            } else {
                
                self.performSegue(withIdentifier: "EditCustomRoutineSegueIdentifier", sender: selectedRoutine)
                
            }
        }
        editAction.backgroundColor = UIColor.flatOrange()
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            
            do {
                
                try context.save()
                
                context.delete(selectedRoutine)
                Routines.remove(at: (indexPath as NSIndexPath).row)
                tableView.deleteRows(at: [indexPath], with: .left)
                
                sendContextToAppleWatch(["routineName":selectedRoutine.name!,"contextType":"RoutineDeleted"])
                deleteFromSpotlight(selectedRoutine.name!)
                
                if Routines.count == 0 {
                    
                    self.tableView.tableFooterView = UIView()
                    self.tableView.reloadEmptyDataSet()
                }
                
            } catch let error as NSError {
                
                print("Fetch failed: \(error.localizedDescription)")
                
                abort()
            }
        
            tableView.isEditing = false
        }
        
        return [deleteAction, editAction]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if Routines.count == 0 {
            
            return false
            
        }
        
        return true
    }
    
//    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        // Return NO if you do not want the item to be re-orderable.
//        return true
//    }
//    
//    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
//        
//        let routineToBeMoved = Routines[fromIndexPath.row]
//        Routines.removeAtIndex(fromIndexPath.row)
//        Routines.insert(routineToBeMoved, atIndex: toIndexPath.row)
//        
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let destinationController = segue.destinationViewController as! UINavigationController
        
        if segue.identifier == "EditCircuitRoutineSegueIdentifier" {
            
            let circuitRoutineTableViewController = destinationController.viewControllers.first as! CircuitRoutineTableViewController
            
            circuitRoutineTableViewController.routineToEdit = sender as! RoutineModel
            circuitRoutineTableViewController.exerciseSet = circuitRoutineTableViewController.routineToEdit.routineToExcercise?.mutableCopy() as! NSMutableOrderedSet
            
        } else if segue.identifier == "EditCustomRoutineSegueIdentifier" {
            
            let customRoutineTableViewController = destinationController.viewControllers.first as! CustomRoutineTableViewController
            customRoutineTableViewController.routineToEdit = sender as! RoutineModel
            customRoutineTableViewController.exerciseSet = customRoutineTableViewController.routineToEdit.routineToExcercise?.mutableCopy() as! NSMutableOrderedSet
        }
    }
}

// DZNEmptyDataSet delegate functions
extension RoutinesTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func imageForEmptyDataSet(_ scrollView: UIScrollView!) -> UIImage! {
        
        return emptyTableGuyImage
    }
    
    func titleForEmptyDataSet(_ scrollView: UIScrollView!) -> AttributedString! {
        
        let attributedTitle: AttributedString = AttributedString(string: NSLocalizedString("Empty Routine Table Title Text", comment: ""), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(_ scrollView: UIScrollView!) -> AttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributedDescription: AttributedString = AttributedString(string: NSLocalizedString("Empty Routine Table Subtitle Text", comment: ""), attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}
