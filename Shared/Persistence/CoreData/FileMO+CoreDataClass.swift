// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.
//

import Foundation
import CoreData

@objc(FileMO)
public class FileMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var csv: Data?
    @NSManaged public var name: String?
    @NSManaged public var session: SessionMO?
}

extension FileMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileMO> {
        return NSFetchRequest<FileMO>(entityName: "FileMO")
    }
}
