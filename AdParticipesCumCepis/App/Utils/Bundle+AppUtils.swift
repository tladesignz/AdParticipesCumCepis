//
//  Bundle+Utils.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 22.10.21.
//

import Foundation

public extension Bundle {

    class var adParticipesCumCepis: Bundle? {
        guard let url = Bundle(for: BaseAppDelegate.self).url(forResource: "AdParticipesCumCepis", withExtension: "bundle") else {
            return nil
        }

        return Bundle(url: url)
    }
}
