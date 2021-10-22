//
//  Bundle+Utils.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 22.10.21.
//

import Foundation

public extension Bundle {

    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
            ?? ""
    }
}
