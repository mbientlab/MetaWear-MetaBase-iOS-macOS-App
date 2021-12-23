// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreData

public protocol CoreDataBackgroundController: AnyObject {
    func makeBackgroundContext() -> NSManagedObjectContext
}

public class CloudKitCoreDataController: CoreDataBackgroundController {

    private let container: NSPersistentCloudKitContainer

    public init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Session")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        configure(context: container.viewContext)
    }

    public func makeBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        configure(context: context)
        return context
    }

    private func configure(context: NSManagedObjectContext) {
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
