//
//  WebServer.swift
//  AdParticipesCumCepis_Example
//
//  Created by Benjamin Erhart on 13.10.21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import AdParticipesCumCepis
import Stencil
import PathKit

class WebServer: AdParticipesCumCepis.WebServer {

    private static let defaultContext: [String: Any] = [
        "static_url_path": "/static"]


    private let renderer: Environment


    init() {
        renderer = Environment(loader: FileSystemLoader(paths: [
            Path(Bundle.main.path(forResource: "templates", ofType: nil)!)]))

        super.init(staticPath: Bundle.main.path(forResource: "static", ofType: nil)!)
    }


    override func renderTemplate(name: String, context: [String : Any]) throws -> String {
        return try self.renderer.renderTemplate(
            name: name.appending(".html"),
            context: WebServer.defaultContext.merging(context, uniquingKeysWith: { $1 }))
    }
}
