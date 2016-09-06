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
public class ExerciseModel: NSManagedObject {
    
    //properties feeding the attributes in "Exercises" entity
    
    @NSManaged public var exerciseName: String!
    @NSManaged public var exerciseTime: NSNumber!
    @NSManaged public var exerciseNumberOfRounds: NSNumber!
    @NSManaged public var exerciseColor: NSData!
    
    @NSManaged open var exerciseToRoutine: RoutineModel?
    
}
