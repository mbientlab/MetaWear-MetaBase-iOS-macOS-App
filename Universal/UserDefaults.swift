//
//  UserDefaults.swift
//  MetaBase
//
//  Created by Stephen Schiffli on 2/14/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import Foundation


fileprivate let encoder = JSONEncoder()
fileprivate let decoder = JSONDecoder()

func saveToDefaults<T: Encodable>(key: String, value: T) {
    if let json = try? encoder.encode(value) {
        UserDefaults.standard.set(json, forKey: key)
    }
}

func loadfromDefaults<T: Decodable>(key: String) -> T? {
    if let data = UserDefaults.standard.value(forKey: key) as? Data {
        return try? decoder.decode(T.self, from: data)
    }
    return nil
}
