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

    @IBAction func runnerButtonPressed(sender: AnyObject) {
        
        guard proFeaturesUpgradePurchased() || ((LaunchKit.sharedInstance().currentUser?.isSuper() == true) && !removeAdsUpgradePurchased()) else {
            IAPHelper.sharedInstance.selectProduct(proVersionKey)
            return
        }
            
        if Routines != nil {
            
            deselectSelectedRoutine()
        }
        
        let timerViewController = mainStoryboard.instantiateViewControllerWithIdentifier("TimerViewController") as! TimerViewController
        timerViewController.initializeRunner()
        
        appDel.window?.rootViewController?.presentViewController(timerViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Meant to remove the cell separators on empty table
        self.tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(animated: Bool) {
        
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return Routines.count ?? 0
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.backgroundColor = UIColor.clearColor()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! RoutineCell
        
        if Routines.count != 0 {
            
                let routine = Routines[indexPath.row]
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
        if Routines.count != 0 {
            
            setSelectedRoutine(Routines[indexPath.row], completion: { (result) -> Void in
                
                let timerViewController = mainStoryboard.instantiateViewControllerWithIdentifier("TimerViewController") as! TimerViewController
                timerViewController.initializeRoutine(with: Routines[indexPath.row])
                
                appDel.window?.rootViewController?.presentViewController(timerViewController, animated: true, completion: nil)
            })
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: true)
        
        if !editing {
            
            var i = Routines.count
            
            for routine in Routines {
                
                routine.setValue(i--, forKey: "tableDisplayOrder")
            
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let selectedRoutine = Routines[indexPath.row]
        
        let editAction = UITableViewRowAction(style: .Default, title: "Edit") { (action, indexPath) -> Void in
            
            if selectedRoutine.type == "Circuit" {
                
                self.performSegueWithIdentifier("EditCircuitRoutineSegueIdentifier", sender: selectedRoutine)
                
            } else {
                
                self.performSegueWithIdentifier("EditCustomRoutineSegueIdentifier", sender: selectedRoutine)
                
            }
        }
        editAction.backgroundColor = UIColor.flatOrangeColor()
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            
            do {
                
                try context.save()
                
                context.deleteObject(selectedRoutine)
                Routines.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                
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
        
            tableView.editing = false
        }
        
        return [deleteAction, editAction]
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
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
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return emptyTableGuyImage
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: NSLocalizedString("Empty Routine Table Title Text", comment: ""), attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributedDescription: NSAttributedString = NSAttributedString(string: NSLocalizedString("Empty Routine Table Subtitle Text", comment: ""), attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}