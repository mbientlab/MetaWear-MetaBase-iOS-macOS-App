// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.
//

import Foundation
import CoreData

@objc(DeviceMO)
public class DeviceMO: NSManagedObject, Identifiable {
    @NSManaged public var mac: String?
    @NSManaged public var session: NSSet?
}

extension DeviceMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeviceMO> {
        return NSFetchRequest<DeviceMO>(entityName: "DeviceMO")
    }

}

// MARK: Generated accessors for session
extension DeviceMO {

    @objc(addSessionObject:)
    @NSManaged public func addToSession(_ value: SessionMO)

    @objc(removeSessionObject:)
    @NSManaged public func removeFromSession(_ value: SessionMO)

    @objc(addSession:)
    @NSManaged public func addToSession(_ values: NSSet)

    @objc(removeSession:)
    @NSManaged public func removeFromSession(_ values: NSSet)

}
