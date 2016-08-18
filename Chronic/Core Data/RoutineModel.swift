//
//  RoutineModel.swift
//  Chronic
//
//  Created by Ahmed E on 13/03/15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData

@objc (RoutineModel)
open class RoutineModel: NSManagedObject {
    
    //properties feeding the attributes in "Routines" entity
    
    @NSManaged open var date: Date?
    @NSManaged open var name: String!
    @NSManaged open var selectedRoutine: Bool
    @NSManaged open var tableDisplayOrder: NSNumber!
    @NSManaged open var totalRoutineTime: NSNumber?
    @NSManaged open var type: String!
    
    @NSManaged open var routineToExcercise: NSOrderedSet?
}

extension RoutineModel {
    @nonobjc class func fetchRequest() -> NSFetchRequest<RoutineModel> {
        return NSFetchRequest<RoutineModel>(entityName: "RoutineModel");
    }
}
