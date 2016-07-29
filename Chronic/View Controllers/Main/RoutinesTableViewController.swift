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

protocol RoutineDelegate {
    func didCreateRoutine(_ routine: RoutineModel)
}

class RoutinesTableViewController: UITableViewController, UIPopoverControllerDelegate, RoutineDelegate {
    
    var routines = [RoutineModel]()

    @IBAction func runnerButtonPressed(_ sender: AnyObject) {
        
        guard proFeaturesUpgradePurchased() || ((LaunchKit.sharedInstance().currentUser?.isSuper() == true) && !removeAdsUpgradePurchased()) else {
            IAPHelper.sharedInstance.selectProduct(proVersionKey)
            return
        }
            
        deselectSelectedRoutine()
        
        let timerViewController = mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
        timerViewController.initializeRunner()
        
        appDel.window?.rootViewController?.present(timerViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Meant to remove the cell separators on empty table
        self.tableView.tableFooterView = UIView()
        
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadData() {
        
        // Get Routines from database
        do {
            
            self.routines = try DataAccess.sharedInstance.GetRoutines(nil)

            self.tableView.reloadData()
        
        } catch {
            // TO-DO: HANDLE ERROR
        }
    }
    
    func didCreateRoutine(_ routine: RoutineModel) {
        
        let indexPath = IndexPath(row: 0, section: 0)
        routines.insert(routine, at: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
        
        self.tableView.reloadEmptyDataSet()
    }
    
    // MARK: -TableView Functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return routines.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RoutineCell
        
        if routines.count != 0 {
            
                let routine = routines[(indexPath as NSIndexPath).row]
                cell.configure(with: routine)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        if routines.count != 0 {
            
            setSelectedRoutine(routines[(indexPath as NSIndexPath).row], completion: { (result) -> Void in
                
                let timerViewController = mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
                timerViewController.initializeRoutine(with: self.routines[(indexPath as NSIndexPath).row])
                
                appDel.window?.rootViewController?.present(timerViewController, animated: true, completion: nil)
            })
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: true)
        
        if !editing {
            
            var i = routines.count
            
            for routine in routines {
                
                i -= 1
                routine.setValue(i , forKey: "tableDisplayOrder")
            
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let selectedRoutine = routines[(indexPath as NSIndexPath).row]
        
        let editAction = UITableViewRowAction(style: .default, title: "Edit") { (action, indexPath) -> Void in
            
            if selectedRoutine.type == "Circuit" {
                
                self.performSegue(withIdentifier: "EditCircuitRoutineSegueIdentifier", sender: selectedRoutine)
                
            } else {
                
                self.performSegue(withIdentifier: "EditCustomRoutineSegueIdentifier", sender: selectedRoutine)
                
            }
        }
        editAction.backgroundColor = UIColor.orange()
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            
            do {
                
                try context.save()
                
                context.delete(selectedRoutine)
                self.routines.remove(at: (indexPath as NSIndexPath).row)
                tableView.deleteRows(at: [indexPath], with: .left)
                
                sendContextToAppleWatch(["routineName":selectedRoutine.name!,"contextType":"RoutineDeleted"])
                deleteFromSpotlight(selectedRoutine.name!)
                
                if self.routines.count == 0 {
                    
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
        
        if routines.count == 0 {
            
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
//        let routineToBeMoved = routines[fromIndexPath.row]
//        routines.removeAtIndex(fromIndexPath.row)
//        routines.insert(routineToBeMoved, atIndex: toIndexPath.row)
//        
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let destinationController = segue.destinationViewController as! UINavigationController
        
        if segue.identifier == "EditCircuitRoutineSegueIdentifier" {
            
            let circuitRoutineTableViewController = destinationController.viewControllers.first as! CircuitRoutineTableViewController
            circuitRoutineTableViewController.delegate = self
            
            circuitRoutineTableViewController.routineToEdit = sender as! RoutineModel
            circuitRoutineTableViewController.exerciseSet = circuitRoutineTableViewController.routineToEdit.routineToExcercise?.mutableCopy() as! NSMutableOrderedSet
            
        } else if segue.identifier == "EditCustomRoutineSegueIdentifier" {
            
            let customRoutineTableViewController = destinationController.viewControllers.first as! CustomRoutineTableViewController
            customRoutineTableViewController.delegate = self
            
            customRoutineTableViewController.routineToEdit = sender as! RoutineModel
            customRoutineTableViewController.exerciseSet = customRoutineTableViewController.routineToEdit.routineToExcercise?.mutableCopy() as! NSMutableOrderedSet
        } else if segue.identifier == "AddRoutineSegueIdentifier" {
            
            let routineTypeViewController = destinationController.viewControllers.first as! RoutineTypeViewController
            routineTypeViewController.delegate = self
        }
    }
}

// DZNEmptyDataSet delegate functions
extension RoutinesTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        
        return emptyTableGuyImage
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        
        let attributedTitle: AttributedString = AttributedString(string: NSLocalizedString("Empty Routine Table Title Text", comment: ""), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributedDescription: AttributedString = AttributedString(string: NSLocalizedString("Empty Routine Table Subtitle Text", comment: ""), attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}
