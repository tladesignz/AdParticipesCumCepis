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


    public var title: String {
        NSLocalizedString("Share", comment: "")
    }

    public var addressLbTextWithPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address and private key can download your files using the Tor Browser:",
            comment: "")
    }

    public var addressLbTextNoPrivateKey: String {
        NSLocalizedString(
            "Anyone with this address can download your files using the Tor Browser:",
            comment: "")
    }

    public var stopSharingAfterSendLb: String {
        NSLocalizedString(
            "Stop sharing after files have been sent (uncheck to allow downloading individual files)",
            comment: "")
    }

    public var stopSharingAfterSendInitialValue: Bool {
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

        do {
            WebServer.shared?.delegate = self
            try WebServer.shared?.start()
        }
        catch {
            return stop(error)
        }

        // Remove all existing keys.
        for i in (0 ..< (TorManager.shared.onionAuth?.keys.count ?? 0)).reversed() {
            TorManager.shared.onionAuth?.removeKey(at: i)
        }

        // Remove the service dir, in order to make Tor create a new service with a new address.
        if let serviceDir = FileManager.default.serviceDir,
           FileManager.default.fileExists(atPath: serviceDir.path)
        {
            do {
                try FileManager.default.removeItem(at: serviceDir)
            }
            catch {
                print("[\(String(describing: type(of: self)))] Can't remove service dir: \(error)")
            }
        }


        // Trigger (re-)creation of directories.
        _ = FileManager.default.pubKeyDir

        var privateKey: String? = nil

        if !publicService {
            // Create a new key pair.
            let keypair = TorX25519KeyPair()

            // Private key needs to be shown to the user.
            privateKey = keypair.privateKey

            // The public key is needed by the onion service, *before* start.
            if let publicKey = keypair.getPublicAuthKey(withName: "share") {
                TorManager.shared.onionAuth?.set(publicKey)
            }
        }

        TorManager.shared.start { progress in
            DispatchQueue.main.async {
                self.progress = Double(progress) / 100
            }
        } _: { error, socksAddr in
            DispatchQueue.main.async {
                if let error = error {
                    return self.stop(error)
                }

                self.state = .running
                self.progress = 1

                let url = TorManager.shared.serviceUrl
                self.address = url

                if let privateKey = privateKey {
                    // After successful start, we should now have a domain.
                    // Time to store the private key for later reuse.
                    if let url = url {
                        TorManager.shared.onionAuth?.set(TorAuthKey(private: privateKey, forDomain: url))
                    }

                    self.key = privateKey
                }
            }
        }
    }

    public func stop(_ error: Error? = nil) {
        TorManager.shared.stop()

        if WebServer.shared?.running ?? false {
            WebServer.shared?.stop()
        }

        WebServer.shared?.delegate = nil

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
