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
    
    var delegate: RoutineDelegate?
    
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
            
            Constants.warmUpExercise = exerciseSet[0] as! ExerciseModel
            Constants.roundExercise = exerciseSet[1] as! ExerciseModel
            Constants.restExercise = exerciseSet[2] as! ExerciseModel
            Constants.coolDownExercise = exerciseSet[3] as! ExerciseModel
            
            WarmUpDuration = Constants.warmUpExercise.exerciseTime as Int
            NumberOfRounds = Constants.roundExercise.exerciseNumberOfRounds as Int
            RoundDuration = Constants.roundExercise.exerciseTime as Int
            RestDuration = Constants.restExercise.exerciseTime as Int
            CoolDownDuration = Constants.coolDownExercise.exerciseTime as Int
            
            self.nameTextField.text = routineToEdit.name
            self.warmUpTimeTextField.text = Functions.timeStringFrom(time:WarmUpDuration, type: "Routine")
            self.numberOfRoundsTextField.text = String(NumberOfRounds)
            self.roundTimeTextField.text = Functions.timeStringFrom(time:RoundDuration, type: "Routine")
            self.restTimeTextField.text = Functions.timeStringFrom(time:RestDuration, type: "Routine")
            self.coolDownTimeTextField.text = Functions.timeStringFrom(time:CoolDownDuration, type: "Routine")
            
            nameTextField.isEnabled = false
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: AnyObject?) -> Bool {
        
        if identifier == "SaveRoutineSegueIdentifier" {
            
            return self.SaveRoutine()
            
        } else {
            
            return true
        }
        
    }
    
    func SaveRoutine() -> Bool {
        
        guard nameTextField.text != ""  else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Routine Name Missing Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Name Missing Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            
            return false
            
        }
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = Functions.timeComponentsFrom(string: self.warmUpTimeTextField.text!)
        
        WarmUpDuration = Functions.timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        NumberOfRounds = Int(self.numberOfRoundsTextField.text!)!
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = Functions.timeComponentsFrom(string: self.roundTimeTextField.text!)
        
        RoundDuration = Functions.timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = Functions.timeComponentsFrom(string: self.restTimeTextField.text!)
        
        RestDuration = Functions.timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        (exerciseHours,exerciseMinutes,exerciseSeconds) = Functions.timeComponentsFrom(string: self.coolDownTimeTextField.text!)
        
        CoolDownDuration = Functions.timeFromTimeComponents(hoursComponent: exerciseHours, minutesComponent: exerciseMinutes, secondsComponent: exerciseSeconds)
        
        if (WarmUpDuration != 0) || (RoundDuration != 0) || (RestDuration != 0) || (CoolDownDuration != 0) {
            
            exerciseSet = NSMutableOrderedSet()
            
            Functions.deselectSelectedRoutine()
            
            let existingRoutine = Functions.getRoutine(nameTextField.text!)
            
            if routineToEdit != nil {
                
                if routineToEdit.name == nameTextField.text {
                    
                    // Warm Up Exercise
                    
                    let warmUpExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    warmUpExercise.exerciseName = NSLocalizedString("Exercise Name Text (Warm Up)", comment: "")
                    
                    warmUpExercise.exerciseTime = WarmUpDuration
                    
                    warmUpExercise.exerciseNumberOfRounds = 1
                    
                    warmUpExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0xFFCD02)) // yellow
                    
                    warmUpExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.add(warmUpExercise)
                    
                    // Round Exercise
                    
                    let roundExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    roundExercise.exerciseName = NSLocalizedString("Exercise Name Text (Round)", comment: "")
                    
                    roundExercise.exerciseTime = RoundDuration
                    
                    roundExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    roundExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0x5AD427)) // greem
                    
                    roundExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.add(roundExercise)
                    
                    // Rest Exercise
                    
                    let restExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    restExercise.exerciseName = NSLocalizedString("Exercise Name Text (Rest)", comment: "")
                    
                    restExercise.exerciseTime = RestDuration
                    
                    restExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    restExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0xFF3A2D)) // red
                    
                    restExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.add(restExercise)
                    
                    // Cool Down Exercise
                    
                    let coolDownExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    coolDownExercise.exerciseName = NSLocalizedString("Exercise Name Text (Cool Down)", comment: "")
                    
                    coolDownExercise.exerciseTime = CoolDownDuration
                    
                    coolDownExercise.exerciseNumberOfRounds = 1
                    
                    coolDownExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0x1D62F0)) // blue
                    
                    coolDownExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.add(coolDownExercise)
                    
                    routineToEdit.routineToExcercise = exerciseSet
                    
                    routineToEdit.selectedRoutine = true
                    routineToEdit!.date = Date()
                    
                    Functions.setSelectedRoutine(routineToEdit, completion: { (result) -> Void in
                    })
                    
                    let (stagesArray, totalTime) = Functions.makeRoutineArray(self.routineToEdit)
                    
                    routineToEdit.totalRoutineTime = totalTime
                    
                    // add routine to spotlight & send context to Watch
                    let totalTimeString = Functions.timeStringFrom(time: routineToEdit.totalRoutineTime! as Int, type: "Routine")
                    
                    Functions.addToSpotlight(routineToEdit.name!, contentDescription: "Total Time: \(totalTimeString)", uniqueIdentifier: routineToEdit.name!, domainIdentifier: "Routines")
                    
                    if Constants.wcSession != nil {
                        Functions.sendContextToAppleWatch(["routineName":routineToEdit.name!, "routineType":routineToEdit.type!, "routineStage": stagesArray, "contextType":"RoutineModified"])
                    }
                    
                    print("Routine renamed: ", routineToEdit)
                    
                } else {
                    
                    SweetAlert().showAlert(NSLocalizedString("Alert: Routine Exists Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Exists Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle: NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                        
                    }
                    
                    return false
                }
                
            } else {
                
                if existingRoutine == nil  {
                    
                    // Warm Up Exercise
                    
                    let warmUpExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    warmUpExercise.exerciseName = NSLocalizedString("Exercise Name Text (Warm Up)", comment: "")
                    warmUpExercise.exerciseTime = WarmUpDuration
                    
                    warmUpExercise.exerciseNumberOfRounds = 1
                    
                    warmUpExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0xFFCD02))
                    
                    warmUpExercise.exerciseToRoutine = newRoutine
                    
                    exerciseSet.add(warmUpExercise)
                    
                    // Round Exercise
                    
                    let roundExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    roundExercise.exerciseName = NSLocalizedString("Exercise Name Text (Round)", comment: "")
                    
                    roundExercise.exerciseTime = RoundDuration
                    
                    roundExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    roundExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0x5AD427))
                    
                    roundExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.add(roundExercise)
                    
                    // Rest Exercise
                    
                    let restExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    restExercise.exerciseName = NSLocalizedString("Exercise Name Text (Rest)", comment: "")
                    
                    restExercise.exerciseTime = RestDuration
                    
                    restExercise.exerciseNumberOfRounds = NumberOfRounds
                    
                    restExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0xFF3A2D))
                    
                    restExercise.exerciseToRoutine = routineToEdit
                    
                    exerciseSet.add(restExercise)
                    
                    // Cool Down Exercise
                    
                    let coolDownExercise = ExerciseModel(entity: Constants.exerciseEntity!, insertInto: Constants.context)
                    
                    coolDownExercise.exerciseName = NSLocalizedString("Exercise Name Text (Cool Down)", comment: "")
                    
                    coolDownExercise.exerciseTime = CoolDownDuration
                    
                    coolDownExercise.exerciseNumberOfRounds = 1
                    
                    coolDownExercise.exerciseColor = NSKeyedArchiver.archivedData(withRootObject: UIColor.colorFromRGB(0x1D62F0))
                    
                    coolDownExercise.exerciseToRoutine = newRoutine
                    
                    exerciseSet.add(coolDownExercise)
                    
                    newRoutine = RoutineModel(entity: Constants.routineEntity!, insertInto: Constants.context)
                    
                    newRoutine.routineToExcercise = exerciseSet
                    
                    newRoutine.name = nameTextField!.text!
                    newRoutine.selectedRoutine = true
                    newRoutine.date = Date()
                    
                    // newRoutine.tableDisplayOrder = Routines.count + 1
                    
                    newRoutine.type = "Circuit"
                    
                    Functions.setSelectedRoutine(newRoutine, completion: { (result) -> Void in
                    })
                    
                    let (stagesArray, totalTime) = Functions.makeRoutineArray(self.newRoutine)
                    
                    newRoutine.totalRoutineTime = totalTime
                    
                    // add routine to spotlight & send context to Watch                        
                    let totalTimeString = Functions.timeStringFrom(time: newRoutine.totalRoutineTime! as Int, type: "Routine")
                    
                    Functions.addToSpotlight(newRoutine.name!, contentDescription: "Total Time: \(totalTimeString)", uniqueIdentifier: newRoutine.name!, domainIdentifier: "Routines")
                    
                    if Constants.wcSession != nil {
                        
//                        let keys = Array(routineToExcercise.entity.attributesByName.keys)
//                        let dict = routineToExcercise.dictionaryWithValuesForKeys(keys)
                        
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
                try Constants.context.save()
                
                // send delegate out
                self.delegate?.didCreateRoutine(routine: newRoutine ?? routineToEdit, isNew: (routineToEdit != nil) ? false : true)
                
                return true
                
            } catch let error as NSError {
                
                print("Fetch failed: \(error.localizedDescription)")
  
                SweetAlert().showAlert("Failed To Save!", subTitle: "Something seems to be missing", style: AlertStyle.warning)
                return false
            }
            
        } else {
            
            SweetAlert().showAlert(NSLocalizedString("Alert: Routine Total Time Title Text", comment: ""), subTitle: NSLocalizedString("Alert: Routine Total Time Subtitle Text", comment: ""), style: AlertStyle.warning, dismissTime: nil, buttonTitle:NSLocalizedString("Ok", comment: ""), buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            
            return false
            
        }
    }
    
    //MARK: -TableView Functions
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.white
            
        }
        
    }
    
    //MARK: - TextField and Touches Functions
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Prevent crashing undo bug
        if (range.length + range.location) > textField.text?.characters.count {
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
