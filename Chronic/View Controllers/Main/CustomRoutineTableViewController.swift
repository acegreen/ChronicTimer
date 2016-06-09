//
//  CustomRoutineTableViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-25.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData
import LaunchKit

class CustomRoutineTableViewController: UITableViewController, UITextFieldDelegate {
    
    var tableRowSelected: NSIndexPath!
    
    var routineToEdit: RoutineModel!
    
    var newRoutine: RoutineModel!
    
    var exerciseSet:NSMutableOrderedSet = NSMutableOrderedSet()
    var exerciseHours: Int = 0
    var exerciseMinutes: Int = 0
    var exerciseSeconds: Int = 0
    
    var nameCell: ExerciseNameTableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.setEditing(true, animated: true)
        
        nameCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! ExerciseNameTableViewCell
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(true)
        
        if routineToEdit != nil {
            
            nameCell.NameTextField.enabled = false
            
        } else {
            
            let newExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
            
            newExercise.exerciseName = ""
            
            newExercise.exerciseTime = 60
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.greenColor())
            
            exerciseSet.addObject(newExercise)
            
            self.tableView.reloadData()
            
            print("exerciseSet", exerciseSet)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        
        if identifier == "SaveRoutineSegueIdentifier" {
            
            return self.SaveRoutine()
            
        } else {
            
            return true
        }
    }
    
    func SaveRoutine() -> Bool {
        
        guard proFeaturesUpgradePurchased() || ((LaunchKit.sharedInstance().currentUser?.isSuper() == true) && !removeAdsUpgradePurchased()) else {
            
            IAPHelper.sharedInstance.selectProduct(proVersionKey)
            
            return false
        }
        
        guard nameCell.NameTextField.text != "" else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Routine Name Missing Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Name Missing Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            
            return false
            
        }
        
        deselectSelectedRoutine()
        
        let existingRoutine = getRoutine(withName: nameCell.NameTextField.text!)
        
        if routineToEdit != nil {
            
            if routineToEdit.name == nameCell.NameTextField.text {
                
                for exercise in exerciseSet.array as! [ExerciseModel] {
                    
                    if exercise.exerciseName == "" {
                        
                        SweetAlert().showAlert(NSLocalizedString("Alert: Exercise Empty Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Exercise Empty Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                        }
                        
                        return false
                        
                    } else {
                        
                        exercise.exerciseToRoutine = routineToEdit
                    }
                }
                
                routineToEdit.routineToExcercise = exerciseSet
                
                routineToEdit.selectedRoutine = true
                routineToEdit!.date = NSDate()
                
                setSelectedRoutine(routineToEdit, completion: { (result) -> Void in
                    
                })
                
                let (stagesArray, totalTime) = makeRoutineArray(self.routineToEdit)
                
                routineToEdit.totalRoutineTime = totalTime
                
                // add routine to spotlight & send context to Watch
                let totalTimeString = timeStringFrom(time:routineToEdit.totalRoutineTime! as Int, type: "Routine")
                
                addToSpotlight(routineToEdit.name!, contentDescription: "Total Time: \(totalTimeString)", uniqueIdentifier: routineToEdit.name!, domainIdentifier: "Routines")
                
                if wcSession != nil {
                    
                    sendContextToAppleWatch(["routineName":routineToEdit.name!, "routineType":routineToEdit.type!, "routineStage":stagesArray, "contextType":"RoutineModified"])
                }
                
                print("\(routineToEdit) renamed")
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: Routine Exists Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Exists Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                }
                
                return false
                
            }
            
        } else {
            
            if existingRoutine == nil  {
                
                for exercise in exerciseSet.array as! [ExerciseModel] {
                    
                    if exercise.exerciseName == "" {
                        
                        SweetAlert().showAlert(NSLocalizedString("Alert: Exercise Empty Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Exercise Empty Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                        }
                        
                        return false
                        
                    } else {
                        
                        exercise.exerciseToRoutine = newRoutine
                    }
                }
                
                newRoutine = RoutineModel(entity: routineEntity!, insertIntoManagedObjectContext: context)
                
                newRoutine.routineToExcercise = exerciseSet
                
                newRoutine.name = nameCell.NameTextField!.text!
                newRoutine.selectedRoutine = true
                newRoutine.date = NSDate()
                
                newRoutine.tableDisplayOrder = Routines.count + 1
                
                newRoutine.type = "Custom"
                
                setSelectedRoutine(newRoutine, completion: { (result) -> Void in
                })
                
                let (stagesArray, totalTime) = makeRoutineArray(self.newRoutine)
                
                newRoutine.totalRoutineTime = totalTime
                
                // add routine to spotlight & send context to Watch if iOS9                
                let totalTimeString = timeStringFrom(time:newRoutine.totalRoutineTime! as Int, type: "Routine")
                
                addToSpotlight(newRoutine.name!, contentDescription: "Total Time: \(totalTimeString)", uniqueIdentifier: newRoutine.name!, domainIdentifier: "Routines")
                
                if wcSession != nil {
                    sendContextToAppleWatch(["routineName":newRoutine.name!, "routineType":newRoutine.type!, "routineStage":stagesArray, "contextType":"RoutineAdded"])
                }
                
                print("New Routine: \(nameCell.NameTextField.text) saved")
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: Routine Exists Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Exists Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                }
                
                return false
                
            }
        }
        
        do {
            
            // save into CoreData
            try context.save()
            
            // Get Routines from database
            Routines = DataAccess.sharedInstance.GetRoutines(nil) as! [RoutineModel]
            
            return true
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            SweetAlert().showAlert("Failed To Save!", subTitle: "Please try again", style: AlertStyle.Warning)
            return false
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        switch (section) {
            
        case (1):
            
            return exerciseSet.count
            
        default:
            
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch (indexPath.section) {
            
        case (0):
            
            let cell = tableView.dequeueReusableCellWithIdentifier("NameCell", forIndexPath: indexPath) as! ExerciseNameTableViewCell
            
            if routineToEdit != nil {
                
                cell.NameTextField.text = routineToEdit.name
            }
            
            return cell
            
        case (1):
            
            let cell = tableView.dequeueReusableCellWithIdentifier("ExerciseCell", forIndexPath: indexPath) as! ExerciseTableViewCell
            
            if exerciseSet.count != 0 && indexPath.row < exerciseSet.count {
                
                let exerciseAtIndexPath = exerciseSet.objectAtIndex(indexPath.row) as! ExerciseModel
                
                cell.excerciseNameTextField.text = exerciseAtIndexPath.exerciseName
                
                cell.exerciseTimeTextField.text = timeStringFrom(time:exerciseAtIndexPath.exerciseTime as! Int, type: "Routine")
                
                cell.exerciseNumberOfRounds.text = String(exerciseAtIndexPath.exerciseNumberOfRounds!)
                
                cell.exerciseColorTextField.backgroundColor = NSKeyedUnarchiver.unarchiveObjectWithData(exerciseAtIndexPath.exerciseColor! as! NSData ) as! UIColor
                
            }
            
            return cell
            
        default:
            
            let cell = tableView.dequeueReusableCellWithIdentifier("AddExerciseCell", forIndexPath: indexPath)
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        switch (indexPath.section) {
            
        case 1:
            
            return true
            
        case 2:
            
            return true
            
        default:
            
            return false
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        
        switch (indexPath.section) {
            
        case (1):
            
            return true
            
        default:
            
            return false
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        let fromIndexSet:NSIndexSet = NSIndexSet(index: fromIndexPath.row)
        
        exerciseSet.moveObjectsAtIndexes(fromIndexSet, toIndex: toIndexPath.row)
        
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        
        if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
            
            return sourceIndexPath
            
        } else {
            
            return proposedDestinationIndexPath
        }
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            if exerciseSet.count > 1 {
                
                // Delete the row from the data source
                if exerciseSet.count != 0 && indexPath.row + 1 <= exerciseSet.count {
                    
                    context.deleteObject(exerciseSet[indexPath.row] as! NSManagedObject)
                    
                    exerciseSet.removeObjectAtIndex(indexPath.row)
                }
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: Exercise Delete Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Exercise Delete Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                }
            }
            
        } else if editingStyle == .Insert {
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            let index:NSIndexPath = NSIndexPath(forRow: self.tableView.numberOfRowsInSection(1), inSection: 1)
            
            let newExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
            
            newExercise.exerciseName = ""
            
            newExercise.exerciseTime = 60
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.greenColor())
            
            exerciseSet.addObject(newExercise)
            
            tableView.insertRowsAtIndexPaths([index], withRowAnimation: .Automatic)
            
        }
        
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        switch (indexPath.section) {
            
        case (2):
            
            return UITableViewCellEditingStyle.Insert
            
        default:
            
            return UITableViewCellEditingStyle.Delete
        }
        
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.backgroundColor = UIColor.clearColor()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.whiteColor()
            
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch (indexPath.section) {
            
        case (2):
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            let index:NSIndexPath = NSIndexPath(forRow: self.tableView.numberOfRowsInSection(1), inSection: 1)
            
            let newExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
            
            newExercise.exerciseName = ""
            
            newExercise.exerciseTime = 60
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.greenColor())
            
            exerciseSet.addObject(newExercise)
            
            tableView.insertRowsAtIndexPaths([index], withRowAnimation: .Automatic)
            
            print("exerciseSet", exerciseSet)
            
        default:
            
            break
        }
        
    }
    
    func exerciseCellLongPressed(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            print("UIGestureRecognizerState Began")
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "exerciseDetailSegue" {
            
            let indexPathofSelectedRow = self.tableView.indexPathForSelectedRow
            
            let destinationVC = segue.destinationViewController as! CustomRoutineExerciseDetailTableViewController
            
            destinationVC.indexOfExercise = indexPathofSelectedRow
            
        }
        
    }
    
    //MARK: - TextField and Touches Functions3
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        let textFieldRowCell:UITableViewCell = textField.superview!.superview as! UITableViewCell
        
        let indexPath = self.tableView.indexPathForCell(textFieldRowCell)
        
        if indexPath?.section == 1 {
            
            let exercise = exerciseSet.objectAtIndex((indexPath?.row)!) as! ExerciseModel
            
            if textField.tag == 1 {
                
                exercise.exerciseName = textField.text!
                
                print("exercise name", exercise.exerciseName)
                
            } else if textField.tag == 2 {
                
                (exerciseHours,exerciseMinutes,exerciseSeconds) = timeComponentsFrom(string: textField.text!)
                
                exercise.exerciseTime = timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
                
            } else if textField.tag == 3 {
                
                exercise.exerciseNumberOfRounds = Int(textField.text!)!
                
            } else if textField.tag == 4 {
                
                exercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(textField.backgroundColor!)
                
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent crashing undo bug – see note below.
        if (range.length + range.location) > textField.text?.characters.count {
            return false
        }
        
        let newLength: NSInteger = (textField.text?.characters.count)! + string.characters.count - range.length
        
        return newLength <= 20
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        super.touchesBegan(touches as Set<UITouch>, withEvent: event)
        self.view.endEditing(true)
        
    }
}
