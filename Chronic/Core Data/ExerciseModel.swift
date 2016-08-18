//
//  ExerciseModel.swift
//  Chronic
//
//  Created by Ahmed E on 13/03/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData

@objc (ExerciseModel)
open class ExerciseModel: NSManagedObject {
    
    //properties feeding the attributes in "Exercises" entity
    
    @NSManaged open var exerciseName: String!
    @NSManaged open var exerciseTime: NSNumber!
    @NSManaged open var exerciseNumberOfRounds: NSNumber!
    @NSManaged open var exerciseColor: Any
    
    @NSManaged open var exerciseToRoutine: RoutineModel?
    
}
