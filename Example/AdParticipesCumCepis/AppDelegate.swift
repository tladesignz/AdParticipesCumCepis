//
//  AppDelegate.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 10/05/2021.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import AdParticipesCumCepis

@UIApplicationMain
class AppDelegate: BaseAppDelegate {

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool
    {
        webServer = WebServer()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

