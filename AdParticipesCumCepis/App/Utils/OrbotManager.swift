//
//  OrbotManager.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 17.06.22.
//

import Foundation
import OrbotKit
import IPtProxyUI

open class OrbotManager: OrbotStatusChangeListener {

    public static let shared = OrbotManager()


    public var bypassPort: UInt16? {
        if lastOrbotInfo.needProxyConfiguredToBypass {
            return lastOrbotInfo.bypassPort
        }

        return nil
    }


    private var lastOrbotInfo = OrbotKit.Info(status: .stopped)

    private weak var tokenAlert: UIAlertController?


    open func start() -> Bool {
        // If Orbot is not installed, we're cool here.
        guard OrbotKit.shared.installed else {
            return true
        }

        OrbotKit.shared.apiToken = Settings.orbotApiToken

        let (info, error) = getOrbotInfo()
        lastOrbotInfo = info

        if case OrbotKit.Errors.httpError(statusCode: 403)? = error {
            messageToken()
            return false
        }

        if info.needProxyConfiguredToBypass && info.bypassPort == nil {
            messageBypassPort()
            return false
        }

        OrbotKit.shared.notifyOnStatusChanges(self)

        return true
    }

    open func stop() {
        OrbotKit.shared.removeStatusChangeListener(self)
    }


    // MARK: OrbotStatusChangeListener

    public func orbotStatusChanged(info: OrbotKit.Info) {
        print("[\(String(describing: type(of: self)))] Orbot status changed: \(info)")

        if info.status == .started {
            // This is only partially synthesized. Get full info.
            lastOrbotInfo = getOrbotInfo().info
        }
        else {
            lastOrbotInfo = info
        }

        TorManager.shared.reconfigureProxy()
    }

    public func statusChangeListeningStopped(error: Error) {
        print("[\(String(describing: type(of: self)))] Orbot listening stopped; error=\(error)")

        if case OrbotKit.Errors.httpError(403) = error {
            messageToken()
        }
    }


    // MARK: Public Methods

    open func received(token: String) {
        tokenAlert?.textFields?.first?.text = token
    }


    // MARK: Private Methods

    private func getOrbotInfo() -> (info: OrbotKit.Info, error: Error?) {
        var info = OrbotKit.Info(status: .stopped)
        var error: Error?

        let group = DispatchGroup()
        group.enter()

        OrbotKit.shared.info { i, e in
            error = e

            if let i = i {
                info = i
            }

            group.leave()
        }

        group.wait()

        return (info, error)
    }

    private func messageToken() {
        var urlc: URLComponents?

        if let urlType = (Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]])?.first {
            if let scheme = (urlType["CFBundleURLSchemes"] as? [String])?.first {
                urlc = URLComponents()
                urlc?.scheme = scheme
                urlc?.path = "token-callback"
            }
        }

        message(
            String(
                format: NSLocalizedString(
                    "You need to request API access with Orbot, in order for %@ to work while Orbot is running.",
                    comment: ""),
                Bundle.main.displayName),
            NSLocalizedString("Request API Access", comment: ""),
            .requestApiToken(needBypass: true, callback: urlc?.url)
        ) { [weak self] vc in
            self?.tokenAlert = AlertHelper.build(title: NSLocalizedString("Access Token", comment: ""), actions: [AlertHelper.cancelAction()])

            if let alert = self?.tokenAlert {
                AlertHelper.addTextField(alert, placeholder: NSLocalizedString("Paste API token here", comment: ""))

                alert.addAction(AlertHelper.defaultAction() { _ in
                    Settings.orbotApiToken = self?.tokenAlert?.textFields?.first?.text ?? ""
                })

                vc.present(alert, animated: false)
            }
        }
    }

    private func messageBypassPort() {
        message(
            String(
                format: NSLocalizedString(
                    "You need to enable bypass mode in Orbot settings for %@ to work while Orbot is running.",
                    comment: ""),
                Bundle.main.displayName),
            NSLocalizedString("Go to Orbot Settings", comment: ""),
            .settings)
    }

    private func message(_ msg: String, _ okTitle: String, _ okCommand: OrbotKit.UiCommand, _ okCallback: ((UIViewController) -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let vc = UIApplication.shared.rootViewController else {
                return
            }

            let message = NSLocalizedString("You have Orbot installed and running, but we cannot bypass it.", comment: "")
            + "\n\n"
            + msg

            let okAction = AlertHelper.defaultAction(okTitle) { _ in
                OrbotKit.shared.open(okCommand) { success in
                    if !success {
                        AlertHelper.present(vc, message: NSLocalizedString("Orbot could not be opened!", comment: ""))
                    }
                }

                okCallback?(vc)
            }

            AlertHelper.present(
                vc,
                message: message,
                title: NSLocalizedString("Orbot Detected", comment: ""),
                actions: [okAction, AlertHelper.cancelAction()])
        }
    }
}
