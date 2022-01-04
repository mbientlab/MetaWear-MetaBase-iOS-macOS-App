// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.
//

import Foundation
import CoreData

@objc(SessionMO)
public class SessionMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var group: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var files: NSSet?
    @NSManaged public var devices: NSSet?
}

extension SessionMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionMO> {
        return NSFetchRequest<SessionMO>(entityName: "SessionMO")
    }
}

// MARK: Generated accessors for files
extension SessionMO {

    @objc(addFilesObject:)
    @NSManaged public func addToFiles(_ value: FileMO)

    @objc(removeFilesObject:)
    @NSManaged public func removeFromFiles(_ value: FileMO)

    @objc(addFiles:)
    @NSManaged public func addToFiles(_ values: NSSet)

    @objc(removeFiles:)
    @NSManaged public func removeFromFiles(_ values: NSSet)

}

// MARK: Generated accessors for devices
extension SessionMO {

    @objc(addDevicesObject:)
    @NSManaged public func addToDevices(_ value: DeviceMO)

    @objc(removeDevicesObject:)
    @NSManaged public func removeFromDevices(_ value: DeviceMO)

    @objc(addDevices:)
    @NSManaged public func addToDevices(_ values: NSSet)

    @objc(removeDevices:)
    @NSManaged public func removeFromDevices(_ values: NSSet)

}
