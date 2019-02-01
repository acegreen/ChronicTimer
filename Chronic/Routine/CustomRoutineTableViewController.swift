//
//  CustomRoutineTableViewController.swift
//  Chronic
//
//  Created by Ace Green on 2015-07-25.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData
import ChronicKit
import LaunchKit

class CustomRoutineTableViewController: UITableViewController, UITextFieldDelegate {
    
    var delegate: RoutineDelegate?
    
    var tableRowSelected: IndexPath!
    
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
        
        nameCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ExerciseNameTableViewCell
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        if routineToEdit != nil {
            
            nameCell.NameTextField.isEnabled = false
            
        } else {
            
            let newExercise = ExerciseModel(entity: DataAccess.exerciseEntity!, insertInto: DataAccess.context)
            
            newExercise.exerciseName = ""
            
            newExercise.exerciseTime = 60
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0x5AD427)) as NSData // green
            
            exerciseSet.add(newExercise)
            
            self.tableView.reloadData()
            
            print("exerciseSet", exerciseSet)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        
        if identifier == "SaveRoutineSegueIdentifier" {
            
            return self.SaveRoutine()
            
        } else {
            
            return true
        }
    }
    
    func SaveRoutine() -> Bool {
        
//        guard Functions.isProFeaturesUpgradePurchased() || ((LaunchKit.sharedInstance().currentUser?.isSuper() == true) && !Functions.isRemoveAdsUpgradePurchased()) else {
//            
//            IAPHelper.sharedInstance.selectProduct(Constants.proVersionKey)
//            
//            return false
//        }
        
        guard nameCell.NameTextField.text != "" else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Routine Name Missing Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Name Missing Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            
            return false
            
        }
        
        Functions.deselectSelectedRoutine()
        
        let existingRoutine = DataAccess.sharedInstance.fetchRoutine(with: nameCell.NameTextField.text!)
        
        if routineToEdit != nil {
            
            if routineToEdit.name == nameCell.NameTextField.text {
                
                for exercise in exerciseSet.array as! [ExerciseModel] {
                    
                    if exercise.exerciseName == "" {
                        
                        SweetAlert().showAlert(NSLocalizedString("Alert: Exercise Empty Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Exercise Empty Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                        }
                        
                        return false
                        
                    } else {
                        
                        exercise.exerciseToRoutine = routineToEdit
                    }
                }
                
                routineToEdit.routineToExcercise = exerciseSet
                
                routineToEdit.selectedRoutine = true
                routineToEdit!.date = Date()
                
                Functions.setSelectedRoutine(routineToEdit, completion: { (result) -> Void in
                    
                })
                
                let (stagesArray, totalTime) = Functions.makeRoutineArray(routine: self.routineToEdit)
                
                routineToEdit.totalRoutineTime = totalTime as NSNumber
                
                // add routine to spotlight & send context to Watch
                Functions.addToSpotlight(routine: routineToEdit, domainIdentifier: "Routines")
                
                if Constants.wcSession != nil {
                    
                    Functions.sendContextToAppleWatch(["routineName":routineToEdit.name!, "routineType":routineToEdit.type!, "routineStage":stagesArray, "contextType":"RoutineModified"])
                }
                
                print("Routine renamed: ", routineToEdit)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: Routine Exists Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Exists Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                }
                
                return false
                
            }
            
        } else {
            
            if existingRoutine == nil  {
                
                for exercise in exerciseSet.array as! [ExerciseModel] {
                    
                    if exercise.exerciseName == "" {
                        
                        SweetAlert().showAlert(NSLocalizedString("Alert: Exercise Empty Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Exercise Empty Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                        }
                        
                        return false
                        
                    } else {
                        
                        exercise.exerciseToRoutine = newRoutine
                    }
                }
                
                newRoutine = RoutineModel(entity: DataAccess.routineEntity!, insertInto: DataAccess.context)
                
                newRoutine.routineToExcercise = exerciseSet
                
                newRoutine.name = nameCell.NameTextField!.text!
                newRoutine.selectedRoutine = true
                newRoutine.date = Date()
                
                //newRoutine.tableDisplayOrder = Routines.count + 1
                
                newRoutine.type = "Custom"
                
                Functions.setSelectedRoutine(newRoutine, completion: { (result) -> Void in
                })
                
                let (stagesArray, totalTime) = Functions.makeRoutineArray(routine: self.newRoutine)
                
                newRoutine.totalRoutineTime = totalTime as NSNumber
                
                // add routine to spotlight & send context to Watch
                Functions.addToSpotlight(routine: newRoutine, domainIdentifier: "Routines")
                
                if Constants.wcSession != nil {
                    Functions.sendContextToAppleWatch(["routineName":newRoutine.name!, "routineType":newRoutine.type!, "routineStage":stagesArray, "contextType":"RoutineAdded"])
                }
                
                print("New Routine: ", newRoutine)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: Routine Exists Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Exists Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                }
                
                return false
                
            }
        }
        
        do {
            
            // save into CoreData
            try DataAccess.context.save()
            
            // send delegate out
            self.delegate?.didCreateRoutine(newRoutine ?? routineToEdit, isNew: (routineToEdit != nil) ? false : true)
            
            return true
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            SweetAlert().showAlert("Failed To Save!", subTitle: "Please try again", style: AlertStyle.warning)
            return false
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        switch (section) {
            
        case (1):
            
            return exerciseSet.count
            
        default:
            
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch ((indexPath as NSIndexPath).section) {
            
        case (0):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "NameCell", for: indexPath) as! ExerciseNameTableViewCell
            
            if routineToEdit != nil {
                
                cell.NameTextField.text = routineToEdit.name
            }
            
            return cell
            
        case (1):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExerciseCell", for: indexPath) as! ExerciseTableViewCell
            
            if exerciseSet.count != 0 && (indexPath as NSIndexPath).row < exerciseSet.count {
                
                let exerciseAtIndexPath = exerciseSet.object(at: (indexPath as NSIndexPath).row) as! ExerciseModel
                
                cell.excerciseNameTextField.text = exerciseAtIndexPath.exerciseName
                
                cell.exerciseTimeTextField.text = Functions.timeStringFrom(time:exerciseAtIndexPath.exerciseTime as! Int)
                
                cell.exerciseNumberOfRounds.text = exerciseAtIndexPath.exerciseNumberOfRounds!.stringValue
                
                cell.exerciseColorTextField.backgroundColor = NSKeyedUnarchiver.unarchiveObject(with: exerciseAtIndexPath.exerciseColor as! Data) as? UIColor
                
            }
            
            return cell
            
        default:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddExerciseCell", for: indexPath)
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        switch ((indexPath as NSIndexPath).section) {
            
        case 1:
            
            return true
            
        case 2:
            
            return true
            
        default:
            
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        
        switch ((indexPath as NSIndexPath).section) {
            
        case (1):
            
            return true
            
        default:
            
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        
        let fromIndexSet:IndexSet = IndexSet(integer: (fromIndexPath as NSIndexPath).row)
        
        exerciseSet.moveObjects(at: fromIndexSet, to: (toIndexPath as NSIndexPath).row)
        
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        if ((sourceIndexPath as NSIndexPath).section != (proposedDestinationIndexPath as NSIndexPath).section) {
            
            return sourceIndexPath
            
        } else {
            
            return proposedDestinationIndexPath
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if exerciseSet.count > 1 {
                
                // Delete the row from the data source
                if exerciseSet.count != 0 && (indexPath as NSIndexPath).row + 1 <= exerciseSet.count {
                    
                    DataAccess.context.delete(exerciseSet[(indexPath as NSIndexPath).row] as! NSManagedObject)
                    
                    exerciseSet.removeObject(at: (indexPath as NSIndexPath).row)
                }
                
                tableView.deleteRows(at: [indexPath], with: .left)
                
            } else {
                
                SweetAlert().showAlert(NSLocalizedString("Alert: Exercise Delete Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Exercise Delete Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                }
            }
            
        } else if editingStyle == .insert {
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            let index:IndexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 1), section: 1)
            
            let newExercise = ExerciseModel(entity: DataAccess.exerciseEntity!, insertInto: DataAccess.context)
            
            newExercise.exerciseName = ""
            
            newExercise.exerciseTime = 60
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0x5AD427)) as NSData // green
            
            exerciseSet.add(newExercise)
            
            tableView.insertRows(at: [index], with: .automatic)
            
        }
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        switch ((indexPath as NSIndexPath).section) {
            
        case (2):
            
            return UITableViewCell.EditingStyle.insert
            
        default:
            
            return UITableViewCell.EditingStyle.delete
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.white
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch ((indexPath as NSIndexPath).section) {
            
        case (2):
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            let index:IndexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 1), section: 1)
            
            let newExercise = ExerciseModel(entity: DataAccess.exerciseEntity!, insertInto: DataAccess.context)
            
            newExercise.exerciseName = ""
            
            newExercise.exerciseTime = 60
            
            newExercise.exerciseNumberOfRounds = 1
            
            newExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.green) as NSData
            
            exerciseSet.add(newExercise)
            
            tableView.insertRows(at: [index], with: .automatic)
            
            print("exerciseSet", exerciseSet)
            
        default:
            
            break
        }
        
    }
    
    func exerciseCellLongPressed(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            print("UIGestureRecognizerState Began")
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
//        if segue.identifier == "exerciseDetailSegue" {
//            
//            let indexPathofSelectedRow = self.tableView.indexPathForSelectedRow
//            
//            let destinationVC = segue.destination as! CustomRoutineExerciseDetailTableViewController
//            
//            destinationVC.indexOfExercise = indexPathofSelectedRow
//            
//        }
    }
    
    //MARK: - TextField and Touches Functions3
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        let textFieldRowCell:UITableViewCell = textField.superview!.superview as! UITableViewCell
        
        let indexPath = self.tableView.indexPath(for: textFieldRowCell)
        
        if (indexPath as NSIndexPath?)?.section == 1 {
            
            let exercise = exerciseSet.object(at: ((indexPath as NSIndexPath?)?.row)!) as! ExerciseModel
            
            if textField.tag == 1 {
                
                exercise.exerciseName = textField.text!
                
                print("exercise name", exercise.exerciseName)
                
            } else if textField.tag == 2 {
                
                (exerciseHours,exerciseMinutes,exerciseSeconds) = Functions.timeComponentsFrom(string: textField.text!)
                
                exercise.exerciseTime = Functions.timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds) as NSNumber
                
            } else if textField.tag == 3 {
                
                exercise.exerciseNumberOfRounds = Int(textField.text!)! as NSNumber
                
            } else if textField.tag == 4 {
                
                exercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: textField.backgroundColor!) as NSData
                
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent crashing undo bug – see note below.
        if let text = textField.text, text.characters.count < (range.length + range.location) {
            return false
        }
        
        let newLength: NSInteger = (textField.text?.characters.count)! + string.characters.count - range.length
        
        return newLength <= 20
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches as Set<UITouch>, with: event)
        self.view.endEditing(true)
        
    }
}
