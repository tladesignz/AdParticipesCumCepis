//
//  Settings.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 08.06.22.
//

import Foundation
import IPtProxyUI

open class Settings: IPtProxyUI.Settings {

    open class var orbotApiToken: String {
        get {
            defaults?.string(forKey: "orbotApiToken") ?? ""
        }
        set {
            defaults?.set(newValue, forKey: "orbotApiToken")
        }
    }
}
