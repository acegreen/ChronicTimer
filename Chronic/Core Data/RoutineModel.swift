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
public class RoutineModel: NSManagedObject {
    
    //properties feeding the attributes in "Routines" entity
    
    @NSManaged public var date: Date?
    @NSManaged public var name: String!
    @NSManaged public var selectedRoutine: Bool
    @NSManaged public var tableDisplayOrder: NSNumber!
    @NSManaged public var totalRoutineTime: NSNumber?
    @NSManaged public var type: String!
    
    @NSManaged public var routineToExcercise: OrderedSet?
}

extension RoutineModel {
    @nonobjc class func fetchRequest() -> NSFetchRequest<RoutineModel> {
        return NSFetchRequest<RoutineModel>(entityName: "RoutineModel");
    }
    
    @NSManaged var timeStamp: Date?
}
