// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import CoreData
import Combine

public protocol CoreDataBackgroundController: AnyObject {
    func setup()
    func makeBackgroundContext() -> NSManagedObjectContext
    var viewContext: NSManagedObjectContext { get }
    var containerDidChange: AnyPublisher<Void,Never> { get }
    var error: AnyPublisher<Error,Never> { get }
}

public class CloudKitCoreDataController: CoreDataBackgroundController {

    public var viewContext: NSManagedObjectContext { container.viewContext }
    public private(set) lazy var containerDidChange: AnyPublisher<Void,Never> = containerDidChangeSubject.share().eraseToAnyPublisher()
    public private(set) lazy var error: AnyPublisher<Error, Never> = errorSubject.share().eraseToAnyPublisher()
    public let inMemory: Bool

    private let containerDidChangeSubject = PassthroughSubject<Void,Never>()
    private let errorSubject = PassthroughSubject<Error,Never>()
    private var container: NSPersistentCloudKitContainer!
    private var didSetup = false

    public init(inMemory: Bool = false) {
        self.inMemory = inMemory
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

    public func setup() {
        guard didSetup == false else { return }
        didSetup = true

        container = {
            let cloud = NSPersistentCloudKitContainer(name: "Sessions")
            let description = cloud.persistentStoreDescriptions.first

            [NSMigratePersistentStoresAutomaticallyOption,
             NSInferMappingModelAutomaticallyOption,
             NSPersistentStoreRemoteChangeNotificationPostOptionKey,
             NSPersistentHistoryTrackingKey
            ].forEach { description?.setOption(true as NSNumber, forKey: $0) }

            return cloud
        }()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(containerChanged),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            guard let error = error else { return }
            self?.errorSubject.send(error)
            NSLog("\(Self.self) \(error.localizedDescription)")
        })

        configure(context: container.viewContext)
    }
}
