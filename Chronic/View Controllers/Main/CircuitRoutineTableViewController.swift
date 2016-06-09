//
//  AddRoutineTableViewController.swift
//  Chronic
//
//  Created by Ahmed E on 10/03/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData

class CircuitRoutineTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField: UITextField!
    
    @IBOutlet var warmUpNameTextField: UILabel!
    @IBOutlet var warmUpTimeTextField: TimePickerTextField!
    
    @IBOutlet var numberOfRoundsTextField: TimePickerTextField!
    
    @IBOutlet var roundNameTextField: UILabel!
    @IBOutlet var roundTimeTextField: TimePickerTextField!
    
    @IBOutlet var restNameTextField: UILabel!
    @IBOutlet var restTimeTextField: TimePickerTextField!
    
    @IBOutlet var coolDownNameTextField: UILabel!
    @IBOutlet var coolDownTimeTextField: TimePickerTextField!
    
    var routineToEdit: RoutineModel!
    
    var newRoutine: RoutineModel!
    var exerciseSet:NSMutableOrderedSet = NSMutableOrderedSet()
    var exerciseHours: Int = 0
    var exerciseMinutes: Int = 0
    var exerciseSeconds: Int = 0
    
    var WarmUpDuration: Int = 60
    var NumberOfRounds:Int = 1
    var RoundDuration: Int = 60
    var RestDuration: Int = 60
    var CoolDownDuration: Int = 60
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if routineToEdit != nil {
            
            exerciseSet = routineToEdit.routineToExcercise as! NSMutableOrderedSet
            
            warmUpExercise = exerciseSet[0] as! ExerciseModel
            roundExercise = exerciseSet[1] as! ExerciseModel
            restExercise = exerciseSet[2] as! ExerciseModel
            coolDownExercise = exerciseSet[3] as! ExerciseModel
            
            WarmUpDuration = warmUpExercise.exerciseTime as Int
            NumberOfRounds = roundExercise.exerciseNumberOfRounds as Int
            RoundDuration = roundExercise.exerciseTime as Int
            RestDuration = restExercise.exerciseTime as Int
            CoolDownDuration = coolDownExercise.exerciseTime as Int
            
            self.nameTextField.text = routineToEdit.name
            self.warmUpTimeTextField.text = timeStringFrom(time:WarmUpDuration, type: "Routine")
            self.numberOfRoundsTextField.text = String(NumberOfRounds)
            self.roundTimeTextField.text = timeStringFrom(time:RoundDuration, type: "Routine")
            self.restTimeTextField.text = timeStringFrom(time:RestDuration, type: "Routine")
            self.coolDownTimeTextField.text = timeStringFrom(time:CoolDownDuration, type: "Routine")
            
            nameTextField.enabled = false
            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(true)
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        
        if identifier == "SaveRoutineSegueIdentifier" {
            
            return self.SaveRoutine()
            
        } else {
            
            return true
        }
        
    }
    
    func SaveRoutine() -> Bool {
        
        guard nameTextField.text != ""  else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Routine Name Missing Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Name Missing Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            
            return false
            
        }
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = timeComponentsFrom(string: self.warmUpTimeTextField.text!)
        
        WarmUpDuration = timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        NumberOfRounds = Int(self.numberOfRoundsTextField.text!)!
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = timeComponentsFrom(string: self.roundTimeTextField.text!)
        
        RoundDuration = timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = timeComponentsFrom(string: self.restTimeTextField.text!)
        
        RestDuration = timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = timeComponentsFrom(string: self.coolDownTimeTextField.text!)
        
        CoolDownDuration = timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        if (WarmUpDuration != 0) || (RoundDuration != 0) || (RestDuration != 0) || (CoolDownDuration != 0) {
            
            exerciseSet = NSMutableOrderedSet()
            
            deselectSelectedRoutine()
            
            let existingRoutine = getRoutine(withName: nameTextField.text!)
            
            if routineToEdit != nil {
                
                if routineToEdit.name == nameTextField.text {
                    
                    // Warm Up Exercise
                    
                    let warmUpExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    warmUpExercise.exerciseName = NSLocalizedString("Exercise Name Text (Warm Up)", comment: "")
                    
                    warmUpExercise.exerciseTime = WarmUpDuration
                    
                    warmUpExercise.exerciseNumberOfRounds = 1
                    
                    warmUpExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.yellowColor())
                    
                    warmUpExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.addObject(warmUpExercise)
                    
                    // Round Exercise
                    
                    let roundExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    roundExercise.exerciseName = NSLocalizedString("Exercise Name Text (Round)", comment: "")
                    
                    roundExercise.exerciseTime = RoundDuration
                    
                    roundExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    roundExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.redColor())
                    
                    roundExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.addObject(roundExercise)
                    
                    // Rest Exercise
                    
                    let restExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    restExercise.exerciseName = NSLocalizedString("Exercise Name Text (Rest)", comment: "")
                    
                    restExercise.exerciseTime = RestDuration
                    
                    restExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    restExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.greenColor())
                    
                    restExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.addObject(restExercise)
                    
                    // Cool Down Exercise
                    
                    let coolDownExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    coolDownExercise.exerciseName = NSLocalizedString("Exercise Name Text (Cool Down)", comment: "")
                    
                    coolDownExercise.exerciseTime = CoolDownDuration
                    
                    coolDownExercise.exerciseNumberOfRounds = 1
                    
                    coolDownExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.blueColor())
                    
                    coolDownExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.addObject(coolDownExercise)
                    
                    routineToEdit.routineToExcercise = exerciseSet
                    
                    routineToEdit.selectedRoutine = true
                    routineToEdit!.date = NSDate()
                    
                    setSelectedRoutine(routineToEdit, completion: { (result) -> Void in
                    })
                    
                    let (stagesArray, totalTime) = makeRoutineArray(self.routineToEdit)
                    
                    routineToEdit.totalRoutineTime = totalTime
                    
                    // add routine to spotlight & send context to Watch
                    let totalTimeString = timeStringFrom(time: routineToEdit.totalRoutineTime! as Int, type: "Routine")
                    
                    addToSpotlight(routineToEdit.name!, contentDescription: "Total Time: \(totalTimeString)", uniqueIdentifier: routineToEdit.name!, domainIdentifier: "Routines")
                    
                    if wcSession != nil {
                        sendContextToAppleWatch(["routineName":routineToEdit.name!, "routineType":routineToEdit.type!, "routineStage": stagesArray, "contextType":"RoutineModified"])
                    }
                    
                    print("\(routineToEdit) renamed")
                    
                } else {
                    
                    SweetAlert().showAlert(NSLocalizedString("Alert: Routine Exists Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Exists Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                        
                    }
                    
                    return false
                }
                
            } else {
                
                if existingRoutine == nil  {
                    
                    // Warm Up Exercise
                    
                    let warmUpExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    warmUpExercise.exerciseName = NSLocalizedString("Exercise Name Text (Warm Up)", comment: "")
                    warmUpExercise.exerciseTime = WarmUpDuration
                    
                    warmUpExercise.exerciseNumberOfRounds = 1
                    
                    warmUpExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.yellowColor())
                    
                    warmUpExercise.exerciseToRoutine = newRoutine
                    
                    exerciseSet.addObject(warmUpExercise)
                    
                    // Round Exercise
                    
                    let roundExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    roundExercise.exerciseName = NSLocalizedString("Exercise Name Text (Round)", comment: "")
                    
                    roundExercise.exerciseTime = RoundDuration
                    
                    roundExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    roundExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.greenColor())
                    
                    roundExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.addObject(roundExercise)
                    
                    // Rest Exercise
                    
                    let restExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    restExercise.exerciseName = NSLocalizedString("Exercise Name Text (Rest)", comment: "")
                    
                    restExercise.exerciseTime = RestDuration
                    
                    restExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    restExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.redColor())
                    
                    restExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.addObject(restExercise)
                    
                    // Cool Down Exercise
                    
                    let coolDownExercise = ExerciseModel(entity: exerciseEntity!, insertIntoManagedObjectContext: context)
                    
                    coolDownExercise.exerciseName = NSLocalizedString("Exercise Name Text (Cool Down)", comment: "")
                    
                    coolDownExercise.exerciseTime = CoolDownDuration
                    
                    coolDownExercise.exerciseNumberOfRounds = 1
                    
                    coolDownExercise.exerciseColor = NSKeyedArchiver.archivedDataWithRootObject(UIColor.blueColor())
                    
                    coolDownExercise.exerciseToRoutine = newRoutine
                    
                    exerciseSet.addObject(coolDownExercise)
                    
                    newRoutine = RoutineModel(entity: routineEntity!, insertIntoManagedObjectContext: context)
                    
                    newRoutine.routineToExcercise = exerciseSet
                    
                    newRoutine.name = nameTextField!.text!
                    newRoutine.selectedRoutine = true
                    newRoutine.date = NSDate()
                    
                    newRoutine.tableDisplayOrder = Routines.count + 1
                    
                    newRoutine.type = "Circuit"
                    
                    setSelectedRoutine(newRoutine, completion: { (result) -> Void in
                    })
                    
                    let (stagesArray, totalTime) = makeRoutineArray(self.newRoutine)
                    
                    newRoutine.totalRoutineTime = totalTime
                    
                    // add routine to spotlight & send context to Watch                        
                    let totalTimeString = timeStringFrom(time: newRoutine.totalRoutineTime! as Int, type: "Routine")
                    
                    addToSpotlight(newRoutine.name!, contentDescription: "Total Time: \(totalTimeString)", uniqueIdentifier: newRoutine.name!, domainIdentifier: "Routines")
                    
                    if wcSession != nil {
                        
//                        let keys = Array(routineToExcercise.entity.attributesByName.keys)
//                        let dict = routineToExcercise.dictionaryWithValuesForKeys(keys)
                        
                        sendContextToAppleWatch(["routineName":newRoutine.name!, "routineType":newRoutine.type!, "routineStage":stagesArray, "contextType":"RoutineAdded"])
                    }
                    
                    print("New Routine: \(nameTextField.text) saved")
                    
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
            
        } else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Routine Total Time Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Total Time Subtitle Text", comment: ""), style: AlertStyle.Warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            
            return false
            
        }
    }
    
    //MARK: -TableView Functions
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.backgroundColor = UIColor.clearColor()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.whiteColor()
            
        }
        
    }
    
    //MARK: - TextField and Touches Functions
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent crashing undo bug
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
