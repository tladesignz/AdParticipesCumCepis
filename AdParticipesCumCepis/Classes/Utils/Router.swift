//
//  Router.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 06.10.21.
//  Copyright (c) 2021 Benjamin Erhart. All rights reserved.
//

import Foundation

open class Router {

    public static let bundle: Bundle = {
        return Bundle(url: Bundle(for: BaseAppDelegate.self).url(forResource: "AdParticipesCumCepis", withExtension: "bundle")!)!
    }()


    open class func main() -> MainViewController {
        return MainViewController(nibName: String(describing: MainViewController.self), bundle: bundle)
    }

    open class func share() -> ShareViewController {
        return ShareViewController(nibName: String(describing: ShareViewController.self), bundle: bundle)
    }
}
