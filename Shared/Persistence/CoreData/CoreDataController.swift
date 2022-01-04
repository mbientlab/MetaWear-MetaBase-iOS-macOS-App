// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreData
import Combine

public protocol CoreDataBackgroundController: AnyObject {
    func makeBackgroundContext() -> NSManagedObjectContext
    var viewContext: NSManagedObjectContext { get }
    var containerDidChange: AnyPublisher<Void,Never> { get }
}

public class CloudKitCoreDataController: CoreDataBackgroundController {

    public let containerDidChange: AnyPublisher<Void,Never>
    public var viewContext: NSManagedObjectContext { container.viewContext }
    private let containerDidChangeSubject = PassthroughSubject<Void,Never>()
    private let container: NSPersistentCloudKitContainer

    public init(inMemory: Bool = false) {
        container = {
            let cloud = NSPersistentCloudKitContainer(name: "Sessions")
            let description = cloud.persistentStoreDescriptions.first
            description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            return cloud
        }()

        self.containerDidChange = containerDidChangeSubject.share().eraseToAnyPublisher()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(containerChanged),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )

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
        context.undoManager?.groupsByEvent = true
    }

    @objc private func containerChanged() {
        containerDidChangeSubject.send()
    }
}
