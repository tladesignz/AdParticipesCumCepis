//
//  ShareModel.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import Tor

open class ShareModel: ObservableObject, WebServerDelegate {

    public enum State {
        case stopped
        case starting
        case running
    }


    open var title: String {
        NSLocalizedString("Share", comment: "")
    }

    open var emptyBackgroundImage: String? {
        nil
    }

    open var addressLbTextWithPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address and private key can download your files using the Tor Browser:",
            comment: "")
    }

    open var addressLbTextNoPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address can download your files using the Tor Browser:",
            comment: "")
    }

    open var stopSharingAfterSendLb: String {
        NSLocalizedString(
            "Stop sharing after files have been sent (uncheck to allow downloading individual files)",
            comment: "")
    }

    open var stopSharingAfterSendInitialValue: Bool {
        true
    }


    @Published public var items = [Item]()

    @Published public var state = State.stopped

    @Published public var progress: Double = 0

    @Published public var error: Error?

    @Published public var address: URL?

    @Published public var key: String?

    public private(set) var stopSharingAfterSend = true

    private var customTitle = ""


    public init() {
        let fm = FileManager.default
        items += fm.contentsOfDirectory(at: fm.docsDir).map { File($0, relativeTo: fm.docsDir) }
    }

    deinit {
        stop()
    }


    public func start(_ publicService: Bool, _ stopSharingAfterSend: Bool, _ customTitle: String) {
        state = .starting
        progress = 0
        error = nil
        address = nil
        key = nil

        self.stopSharingAfterSend = stopSharingAfterSend
        self.customTitle = customTitle

        TorManager.shared.start(for: serviceName, publicService) { progress in
            DispatchQueue.main.async {
                self.progress = Double(progress) / 100
            }
        } _: { error, socksAddr, serviceUrl, privateKey in
            DispatchQueue.main.async {
                if let error = error {
                    return self.stop(error)
                }

                self.state = .running
                self.progress = 1

                guard let url = serviceUrl,
                      let host = url.host
                else {
                    return self.stop(nil)
                }

                self.address = url
                self.key = privateKey

                do {
                    try WebServer.shared?.start(for: host, delegate: self)
                }
                catch {
                    return self.stop(error)
                }
            }
        }
    }

    public func stop(_ error: Error? = nil) {
        TorManager.shared.stop(for: serviceName)

        WebServer.shared?.stop(for: address?.host)

        state = .stopped
        progress = 0
        self.error = error
        address = nil
        key = nil
    }


    // MARK: WebServerDelegate

    public var mode: WebServer.Mode {
        return .share
    }

    public var serviceName: String {
        return "share"
    }

    public var templateName: String {
        return "send"
    }

    public var useCsp: Bool {
        return true
    }

    public func context(for item: Item?) -> [String : Any] {
        var items = items
        var breadcrumbs = [[String]]()
        var breadcrumbs_leaf = "/"

        if let dir = item as? File, dir.isDir {
            items = dir.children()

            if var pc = dir.relativePath?.components(separatedBy: "/") {
                breadcrumbs_leaf = pc.removeLast()

                breadcrumbs.append(["home", "/"])

                for i in 0 ..< pc.count {
                    breadcrumbs.append([pc[i], "/\(pc[0...i].joined(separator: "/"))/"])
                }
            }
        }

        return [
            "breadcrumbs": breadcrumbs,
            "breadcrumbs_leaf": breadcrumbs_leaf,
            "download_individual_files": !stopSharingAfterSend,
            // Always show the total size of *all* files, because *all* files end up in the ZIP file!
            "filesize_human": ByteCountFormatter.string(
                fromByteCount: self.items.reduce(0, { $0 + ($1.size ?? 0) }), countStyle: .file),
            "dirs": items.filter({ $0.isDir }),
            "files": items.filter({ !$0.isDir }),
            "title": customTitle
        ]
    }

    public func downloadFinished() {
        if stopSharingAfterSend {
            stop()
        }
    }
}
