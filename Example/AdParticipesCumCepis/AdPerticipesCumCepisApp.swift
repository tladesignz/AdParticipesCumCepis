//
//  AdPerticipesComCepisApp.swift
//  AdParticipesCumCepis_Example
//
//  Created by Benjamin Erhart on 17.12.21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import SwiftUI
import AdParticipesCumCepis

@main
struct AdPerticipesCumCepisApp: App {

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }

    @UIApplicationDelegateAdaptor(BaseAppDelegate.self)
    var appDelegate


    init() {
        BaseAppDelegate.appGroupId = Config.appGroupId

        WebServer.shared = WebServer()

        print("[\(String(describing: type(of: self)))] cacheDir=\(FileManager.default.cacheDir?.path ?? "nil")")

//        for file in FileManager.default.contentsOfDirectory(at: FileManager.default.cacheDir) {
//            try? FileManager.default.removeItem(at: file)
//        }
    }
}
