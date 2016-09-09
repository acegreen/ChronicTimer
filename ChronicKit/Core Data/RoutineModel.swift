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
    @NSManaged public var totalRoutineTime: NSNumber!
    @NSManaged public var type: String!
    
    @NSManaged public var routineToExcercise: NSOrderedSet?
}

extension RoutineModel {
    
    @nonobjc public class func fetchRoutineRequest() -> NSFetchRequest<RoutineModel> {
        return NSFetchRequest<RoutineModel>(entityName: "RoutineModel");
    }
    
    @nonobjc public var searchDescription: String {
        
        let totalTimeString = self.timeStringFrom(time: self.totalRoutineTime as Int)
        return "Total Time: \(totalTimeString)"
    }
    
    func timeComponentsFrom(time: Int) -> (HoursLeft: Int, MinutesLeft: Int, SecondsLeft: Int) {
        
        let HoursLeft = time/3600
        let MinutesLeft = (time%3600)/60
        let SecondsLeft = (((time%3600)%60)%60)
        
        return (HoursLeft, MinutesLeft, SecondsLeft)
    }
    
    func timeStringFrom(time: Int) -> String {
        
        let (HoursLeft,MinutesLeft,SecondsLeft) = timeComponentsFrom(time: time)
        
        if HoursLeft == 0 {
            return String(format:"%.2d:%.2d", MinutesLeft, SecondsLeft)
        } else {
            return String(format:"%2d:%.2d:%.2d", HoursLeft, MinutesLeft, SecondsLeft)
        }
    }
}
