//
//  Router.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 06.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import SwiftUI

open class Router {

    public static let bundle: Bundle = {
        return Bundle(url: Bundle(for: BaseAppDelegate.self)
                        .url(forResource: "AdParticipesCumCepis", withExtension: "bundle")!)!
    }()

    public static var webServer: WebServer?


    open class func main() -> MainView {
        return MainView()
    }

    open class func share() -> ShareView {
        return ShareView(ShareModel())
    }

    open class func showQr() -> ShowQrViewController {
        return ShowQrViewController(nibName: String(describing: ShowQrViewController.self), bundle: bundle)
    }

    open class func host() -> ShareView {
        return ShareView(HostModel())
    }
}
