//
//  ActionViewController.swift
//  ActionExtension
//
//  Created by Benjamin Erhart on 22.03.22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import AdParticipesCumCepis

class ActionViewController: AdParticipesCumCepis.ActionViewController {

    class override var appGroupId: String {
        return Config.appGroupId
    }
}
