//
//  ActionViewController.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 22.03.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import MBProgressHUD

open class ActionViewController: UIViewController {

    open class var appGroupId: String {
        return ""
    }


    open var progress = Progress()

    open lazy var hud: MBProgressHUD = {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.minShowTime = 1
        hud.label.text = String(format: NSLocalizedString("Adding to %@…", comment: ""), Bundle.main.displayName)
        hud.mode = .determinate
        hud.progressObject = progress

        return hud
    }()

    open var notificationsAllowed = false


    open override func viewDidLoad() {
        super.viewDidLoad()

        UNUserNotificationCenter.current().requestAuthorization(options: .alert) { granted, error in
            self.notificationsAllowed = granted
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }

        hud.show(animated: true)

        for item in items {
            guard let attachments = item.attachments else {
                continue
            }

            for provider in attachments {
                if !provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    continue
                }

                progress.totalUnitCount += 1

                provider.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { item, error in

                    if let error = error {
                        return self.onCompletion(error)
                    }

                    let error = NSLocalizedString("Couldn't add item!", comment: "")

                    let fm = FileManager.default

                    guard let url = item as? URL,
                          let dest = fm.shareDir(of: Self.appGroupId)?.appendingPathComponent(url.lastPathComponent)
                    else {
                        return self.onCompletion(error: error)
                    }

                    do {
                        try fm.copyItem(at: url, to: dest)

                        self.onCompletion(error: nil)
                    }
                    catch {
                        self.onCompletion(error: error.localizedDescription)
                    }
                }
            }
        }
    }

    /**
     Callback for when done with handling an item.

     - Show error message, if any.
     - Increase progress count.
     - Leave ActionViewController, if done.
     - Delay leave by 5 seconds, when error happened.

     - parameter error: An optional localized error string to show to the user.
     */
    open func onCompletion(_ error: Error) {
        onCompletion(error: error.localizedDescription)
    }

    /**
     Callback for when done with handling an item.

     - Show error message, if any.
     - Increase progress count.
     - Leave ActionViewController, if done.
     - Delay leave by 5 seconds, when error happened.

     - parameter error: An optional localized error string to show to the user.
     */
    open func onCompletion(error: String? = nil) {
        var showLonger = false

        if let error = error {
            showLonger = true

            DispatchQueue.main.async {
                self.hud.detailsLabel.text = error
            }
        }

        progress.completedUnitCount += 1

        if progress.completedUnitCount == progress.totalUnitCount {
            showNotification()

            showLonger = showLonger // last asset had an error
                || !notificationsAllowed // user didn't allow notifications, so show text in HUD instead
                || !(hud.detailsLabel.text?.isEmpty ?? true) // earlier asset had an error

            DispatchQueue.main.asyncAfter(deadline: .now() + (showLonger ? 5 : 0.5)) {
                self.done()
            }
        }
    }

    open func showNotification() {
        if notificationsAllowed {
            let content = UNMutableNotificationContent()

            content.body = String.localizedStringWithFormat(
                NSLocalizedString("You have %1$u item(s) ready to share.", comment: "#bc-ignore!"),
                progress.totalUnitCount)

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)

            let request = UNNotificationRequest(
                identifier: String(format: "%@_notification_id", Bundle.main.displayName),
                content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
        else {
            DispatchQueue.main.async {
                self.hud.label.text = NSLocalizedString("Go to the app to share!", comment: "")
            }
        }
    }

    open func done() {
        extensionContext?.completeRequest(returningItems: extensionContext?.inputItems)
    }
}
