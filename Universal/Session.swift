//
//  Capture.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 7/25/16.
//  Copyright © 2016 MBIENTLAB, INC. All rights reserved.
//

// Import this header into your Swift bridge header file to
// let Armor know that PFObject privately provides most of
// the methods for PFSubclassing.
//import Parse
import BoltsSwift


/*class Session : PFObject, PFSubclassing {
    @NSManaged var mac: String
    @NSManaged var started: Date
    @NSManaged var name: String
    @NSManaged var model: String
    @NSManaged var firmwareRev: String
    @NSManaged var platform: String
    @NSManaged var appRev: String
    @NSManaged var appName: String
    @NSManaged var location: PFGeoPoint
    @NSManaged var shipment: Shipment
    //TODO @NSManaged var note: String
    
    @NSManaged var sensors: [[String: AnyObject]]
    
    static func parseClassName() -> String {
        return "MetaBaseSessionV4"
    }
    
    static func from(model: SessionModel, user: PFUser?, location: PFGeoPoint? = nil) -> Session {
        let session = Session()
        if let user = user {
            session.acl = PFACL(user: user)
        }
        session.mac = model.mac
        session.started = model.started
        session.name = model.name
        session.model = model.model
        session.firmwareRev = model.firmwareRev
        session.platform = "iOS"
        session.appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        session.appRev = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        session.sensors = model.files.map { ["data": $0.csvFilename.documentDirectoryUrl.asMetaCloudData(), "name": $0.name as AnyObject] }
        #if TRACKER
            if let shipmentId = device.scanResponsePayload {
                session.shipment = Shipment(withoutDataWithObjectId: shipmentId)
            }
        #endif
        if let location = location {
            session.location = location
        }
        //TODO session.note = model.note
        return session
    }
}

extension URL {
    func asMetaCloudData() -> AnyObject {
        guard let file = try? String(contentsOf: self, encoding: .utf8) else {
            return [] as AnyObject
        }
        let lines = file.components(separatedBy: .newlines)
        guard lines.count > 0 else {
            return [] as AnyObject
        }
        let data: [[AnyObject]] = lines[1...].map {
            let entries = $0.components(separatedBy: ",")
            guard entries.count > 3 else {
                return []
            }
            guard let values = entries[3...].map({ Float($0) }) as? [Float],
                  let epoch = Double(entries[0]) else {
                    return []
            }
            let entry: [AnyObject] = [Date(timeIntervalSince1970: epoch / 1000.0) as AnyObject]
            return entry + (values as [AnyObject])
        }.filter{ !$0.isEmpty }
        return data as AnyObject
    }
}*/
