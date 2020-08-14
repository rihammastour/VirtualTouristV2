//
//  DataController.swift
//  VirtualTourist
//
//  Created by Riham Mastour on 22/12/1441 AH.
//  Copyright © 1441 Riham Mastour. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistanceContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return persistanceContainer.viewContext
    }
    
    var backgroundContext : NSManagedObjectContext!
    
    init(modelName: String) {
        persistanceContainer = NSPersistentContainer(name: modelName)
    }
    
    func configContext(){
        backgroundContext = persistanceContainer.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        
    }
    func load(completion: (() -> Void)? = nil) {
        persistanceContainer.loadPersistentStores(completionHandler: { (storeDesc, err) in
            guard err == nil else {
                fatalError(err!.localizedDescription)
            }
            self.autoSaveiewContext()
            self.configContext()
            completion?()
        })
    }
}

extension DataController {
    func autoSaveiewContext(time: TimeInterval = 30) {
        print("autosaiving")
        guard time > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            self.autoSaveiewContext(time: time)
        }
    }
}
