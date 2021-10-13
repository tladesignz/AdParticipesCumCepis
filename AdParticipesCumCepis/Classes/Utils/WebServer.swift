//
//  WebServer.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//

import Foundation
import GCDWebServer

public protocol WebServerDelegate {

    var templateName: String { get }

    var statusCode: Int { get }

    var context: [String: Any] { get }
}

open class WebServer {

    var delegate: WebServerDelegate? = nil


    private let webServer = GCDWebServer()


    public init(staticPath: String) {
        webServer.addGETHandler(
            forBasePath: "/", directoryPath: staticPath,
            indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)

        webServer.addHandler(forMethod: "GET", pathRegex: ".*\\.html", request: GCDWebServerRequest.self) { _ in
            var html = "<html><body><h1>Internal Server Error</h1></body></html>"
            var statusCode = 500

            do {
                html = try self.renderTemplate(name: self.delegate?.templateName ?? "404",
                                               context: self.delegate?.context ?? [:])

                statusCode = self.delegate?.statusCode ?? 404
            }
            catch {
                print("[\(String(describing: type(of: self)))] error: \(error.localizedDescription)")
            }

            let res = GCDWebServerDataResponse(html: html)
            res?.statusCode = statusCode

            return res
        }

        // Redirect request to root directory to "index.html".
        webServer.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self) {
            return GCDWebServerResponse(redirect: URL(string: "index.html", relativeTo: $0.url)!, permanent: false)
        }
    }


    // MARK: Public Methods

    open func start() throws {
        try webServer.start(options: [
            GCDWebServerOption_Port: TorManager.webServerPort,
            GCDWebServerOption_AutomaticallySuspendInBackground: false])
    }

    open func stop() {
        webServer.stop()
    }

    open func renderTemplate(name: String, context: [String: Any]) throws -> String {
        fatalError("Subclasses need to implement the `renderTemplate()` method.")
    }
}
