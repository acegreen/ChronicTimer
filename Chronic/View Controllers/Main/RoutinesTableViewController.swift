//
//  RoutinesTableViewController.swift
//  Chronic
//
//  Created by Ahmed E on 10/03/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import ChronicKit
import QuartzCore
import DZNEmptyDataSet
import LaunchKit
import SDVersion

protocol RoutineDelegate {
    func didCreateRoutine(_ routine: RoutineModel, isNew: Bool)
}

class RoutinesTableViewController: UITableViewController, UIPopoverControllerDelegate, RoutineDelegate {
    
    var routines = [RoutineModel]()

    @IBAction func runnerButtonPressed(_ sender: AnyObject) {
        
//        guard Functions.isProFeaturesUpgradePurchased() || ((LaunchKit.sharedInstance().currentUser?.isSuper() == true) && !Functions.isRemoveAdsUpgradePurchased()) else {
//            IAPHelper.sharedInstance.selectProduct(Constants.proVersionKey)
//            return
//        }
        
        Functions.deselectSelectedRoutine()
        
        let timerViewController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
        timerViewController.initializeRunner()
        
        Constants.appDel.window?.rootViewController?.present(timerViewController, animated: true, completion: nil)
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
            
            self.routines = try DataAccess.sharedInstance.fetchRoutines(with: nil)

            self.tableView.reloadData()
        
        } catch {
            // TO-DO: HANDLE ERROR
        }
    }
    
    func didCreateRoutine(_ routine: RoutineModel, isNew: Bool) {
        
        if !isNew {
            
            if let indexOfRoutine = routines.index(of: routine) {
                let indexPath = IndexPath(row: indexOfRoutine, section: 0)
                routines.removeObject(routine)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        let indexPath = IndexPath(row: 0, section: 0)
        routines.insert(routine, at: 0)
        
        self.tableView.insertRows(at: [indexPath], with: .automatic)
        self.tableView.reloadEmptyDataSet()
    }
    
    // MARK: -TableView Functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return routines.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if let size: DeviceVersion = SDiOSVersion.deviceVersion(), size == .iPadPro12Dot9Inch || size == .iPadPro9Dot7Inch {
            return 300
        }
        
        return 200
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
            
            Functions.setSelectedRoutine(routines[(indexPath as NSIndexPath).row], completion: { (result) -> Void in
                
                let timerViewController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "TimerViewController") as! TimerViewController
                timerViewController.initializeRoutine(with: self.routines[(indexPath as NSIndexPath).row])
                
                Constants.appDel.window?.rootViewController?.present(timerViewController, animated: true, completion: nil)
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
        editAction.backgroundColor = UIColor.orange
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            
            do {
                
                try DataAccess.context.save()
                
                DataAccess.context.delete(selectedRoutine)
                self.routines.remove(at: (indexPath as NSIndexPath).row)
                tableView.deleteRows(at: [indexPath], with: .left)
                
                Functions.sendContextToAppleWatch(["routineName":selectedRoutine.name!,"contextType":"RoutineDeleted"])
                Functions.deleteFromSpotlight(selectedRoutine.name!)
                
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let destinationController = segue.destination as! UINavigationController
        
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
        
        return Constants.emptyRoutineTableIcon
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: NSLocalizedString("Empty Routine Table Title Text", comment: ""), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24), NSForegroundColorAttributeName: UIColor.white])
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributedDescription: NSAttributedString = NSAttributedString(string: NSLocalizedString("Empty Routine Table Subtitle Text", comment: ""), attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.white, NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}
