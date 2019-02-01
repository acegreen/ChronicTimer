//
//  DataAccess.swift
//  Chronic
//
//  Created by Ace Green on 2015-05-08.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData
import ChronicKit

public class DataAccess {
    
    static let sharedInstance = DataAccess()
    
    static let context = sharedInstance.managedObjectContext
    static let routineEntity = NSEntityDescription.entity(forEntityName: "Routines", in: context)
    static let exerciseEntity = NSEntityDescription.entity(forEntityName: "Exercises", in: context)
    
    static let oldLocationURL = sharedInstance.applicationDocumentsDirectory.appendingPathComponent("Chronic.sqlite")
    static let newLocationURL = sharedInstance.applicationGroupDocumentDirectory.appendingPathComponent("Chronic.sqlite")
    
    static let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
    
    //MARK: -Get Routines & Exercises Functions
    
    public func fetchRoutines(with predicate: NSPredicate?) throws -> [RoutineModel] {
        
        let request: NSFetchRequest<RoutineModel> = RoutineModel.fetchRoutineRequest()
        request.entity = DataAccess.routineEntity
        
        if predicate != nil {
            request.predicate = predicate
        }
        
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.sortDescriptors = sortDescriptors
        
        do {
            
            let results = try self.managedObjectContext.fetch(request)
            return results
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            
            throw error
        }
    }
    
    public func fetchRoutine(with objectID: NSManagedObjectID) -> NSManagedObject? {
        
        do {
            
            return try self.managedObjectContext.existingObject(with: objectID)
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetchRoutine(with name: String) -> RoutineModel? {
        
        let existingRoutinePredicate: NSPredicate = NSPredicate(format: "name == %@", name)
        
        do {
            
            return try self.fetchRoutines(with: existingRoutinePredicate).first
            
        } catch {
            // TO-DO: HANDLE ERROR
            return nil
        }
    }
    
    public func fetchSelectedRoutine() -> RoutineModel? {
        
        let selectedRoutinePredicate: NSPredicate = NSPredicate(format: "selectedRoutine == true")
        
        do {
            
            return try self.fetchRoutines(with: selectedRoutinePredicate).first
            
        } catch {
            // TO-DO: HANDLE ERROR
            return nil
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var applicationGroupDocumentDirectory: URL = {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.AG.Chronic")!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let chronicKitBundle = Bundle(identifier: "AG.ChronicKit")!
        
        let modelURL = chronicKitBundle.url(forResource: "Chronic", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: DataAccess.newLocationURL, options: DataAccess.options)
            
        } catch {
            
            // Report any error we got.
            var dict = [String: Any]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            
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
    
    func checkIfMigrationRequired(oldLocationURL: URL, newLocationURL: URL) -> (needsMigration: Bool, targetURL: URL) {
        
        var needsMigration: Bool = false
        var targetURL: URL = DataAccess.newLocationURL
        
        if FileManager.default.fileExists(atPath: oldLocationURL.path) {
            needsMigration = true
            targetURL = DataAccess.oldLocationURL
        }
        
        if FileManager.default.fileExists(atPath: newLocationURL.path) {
            needsMigration = false
            targetURL = DataAccess.newLocationURL
        }
        
        print(needsMigration ,targetURL)
        return (needsMigration ,targetURL)
    }
    
    func migrateCoreDataStore(from oldLocationURL: URL, to newLocationURL: URL) {
        
        if FileManager.default.fileExists(atPath: oldLocationURL.path) {
            do {
                
                if let newStore = self.persistentStoreCoordinator.persistentStore(for: newLocationURL) {
                    try self.persistentStoreCoordinator.remove(newStore)
                }
                
                let oldStore = try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: oldLocationURL, options: DataAccess.options)
                try self.persistentStoreCoordinator.migratePersistentStore(oldStore, to: newLocationURL, options: DataAccess.options, withType: NSSQLiteStoreType)
                try FileManager.default.removeItem(at: oldLocationURL)
                
                print("CoreData store moved")
            }
            catch let error {
                print(error)
            }
        }
    }
}
