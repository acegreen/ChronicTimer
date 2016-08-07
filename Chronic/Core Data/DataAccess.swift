//
//  DataAccess.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-08.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData

public class DataAccess: NSObject {
    
    static let sharedInstance = DataAccess()
    
    //MARK: -Get Routines & Exercises Functions
    
    public func GetExistingRoutineWith(_ objectID: NSManagedObjectID) -> NSManagedObject? {
        
        do {
            
            return try self.managedObjectContext.existingObject(with: objectID)
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    public func GetRoutines(_ predicate: NSPredicate?) throws -> [RoutineModel] {
        
        let request: NSFetchRequest<RoutineModel> = RoutineModel.fetchRequest()
        let entity = NSEntityDescription.entity(forEntityName: "Routines", in: self.managedObjectContext)
        request.entity = entity
        
        if predicate != nil {
            
            request.predicate = predicate
        }
        
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.sortDescriptors = sortDescriptors
        
        do {
            
            let results = try Constants.context.fetch(request)
            return results
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            
            throw error
            
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "AG.Test" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Chronic", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = try! self.applicationDocumentsDirectory.appendingPathComponent("Chronic.sqlite")
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
            
        } catch {
            
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as? NSError
            
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
