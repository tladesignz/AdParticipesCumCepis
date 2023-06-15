//
//  AppDelegate.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI
import UserNotifications
import IPtProxy

open class BaseAppDelegate: UIResponder, UIApplicationDelegate {

    public static var appGroupId: String?

    public static weak var shared: BaseAppDelegate?

    public static let unWarningId = "warning-return-to-app"


    private var backgroundTaskId = UIBackgroundTaskIdentifier.invalid

    private var unCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    private var oldPhase = ScenePhase.inactive

    open lazy var warningNotificationContent: UNMutableNotificationContent = {
        let content = UNMutableNotificationContent()

        content.title = Bundle.main.displayName
        content.body = NSLocalizedString("The app needs to be open to work.", comment: "")
        content.sound = .default

        return content
    }()


    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        Self.shared = self

        if let ptDir = FileManager.default.ptDir?.path
        {
            IPtProxy.setStateLocation(ptDir)
        }

        askNotifications()

        moveSharedFiles()

        return true
    }

    open func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

        guard WebServer.shared?.running ?? false else {
            return
        }

        // Set back to normal, if it is currently active.
        Dimmer.shared.stop(animated: false)

        backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        DispatchQueue.global(qos: .default).async { [weak self] in
            while self?.backgroundTaskId ?? .invalid != .invalid && UIApplication.shared.backgroundTimeRemaining > 15 {
                Thread.sleep(forTimeInterval: 5)
            }

            // Do nothing, when `backgroundTaskId == .invalid`, as that means the user already returned.
            guard (self?.backgroundTaskId ?? .invalid) != .invalid else {
                return
            }

            self?.notifyUserBeforeEnd()
        }
    }

    open func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    open func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        endBackgroundTask()

        moveSharedFiles()
    }

    open func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

        endBackgroundTask()

        if WebServer.shared?.running ?? false {
            Dimmer.shared.start()
        }
    }

    open func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        endBackgroundTask()
    }

    /**
     Keep old-school lifecycle callbacks with this workaround for SwiftUI 2.
     */
    open func changeOf(scenePhase newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            switch oldPhase {
            case .inactive, .active:
                applicationDidEnterBackground(UIApplication.shared)

            default:
                break
            }

        case .inactive:
            switch oldPhase {
            case .background:
                applicationWillEnterForeground(UIApplication.shared)

            case .active:
                applicationWillResignActive(UIApplication.shared)

            default:
                break
            }

        case .active:
            switch oldPhase {
            case .background, .inactive:
                applicationDidBecomeActive(UIApplication.shared)

            default:
                break
            }

        @unknown default:
            print("[\(String(describing: type(of: self)))] onChange(of: scenePhase), newPhase=unknown default")
        }

        oldPhase = newPhase
    }

    open func handle(url: URL) {
        guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        if urlc.path == "token-callback" {
            if let token = urlc.queryItems?.first(where: { $0.name == "token" })?.value {
                OrbotManager.shared.received(token: token)
            }
        }
    }

    open func moveSharedFiles(modes: [WebServer.Mode] = WebServer.Mode.allCases) {
        // Move new stuff from action extension.
        let fm = FileManager.default

        // Make sure, root folders exist.
        for mode in modes {
            if !fm.fileExists(at: mode.rootFolder) {
                do {
                    try fm.createDirectory(at: mode.rootFolder)
                }
                catch {
                    print("[\(String(describing: type(of: self)))] Error while creating dir \"\(mode.rootFolder!.path)\": \(error.localizedDescription)")
                }
            }
        }

        var needsUpdate = false

        // Move shared files, if any.
        for file in fm.contentsOfDirectory(at: fm.shareDir(of: Self.appGroupId)) {
            // Special folder - ignore.
            guard file.lastPathComponent != "Library" else {
                continue
            }

            var dst1: URL?

            // Find one root folder to move this file to. Maybe the first already contains a file
            // with this name so try all of them until we find a place.
            for mode in modes {
                dst1 = mode.rootFolder?
                    .appendingPathComponent(file.lastPathComponent)

                do {
                    try fm.moveItem(at: file, to: dst1)
                    needsUpdate = true
                    break
                }
                catch {
                    print("[\(String(describing: type(of: self)))] Error while moving file from \"\(file.path)\" to \"\(dst1!.path)\": \(error.localizedDescription)")

                    dst1 = nil
                }
            }

            // Couldn't find a place to move this file to. Try to delete it in its limbo
            // place and continue with the next.
            if dst1 == nil {
                do {
                    try fm.removeItem(at: file)
                }
                catch {
                    print("[\(String(describing: type(of: self)))] Error while deleting file \"\(file.path)\": \(error.localizedDescription)")
                }
            }


            // Hard link all others, so we don't do physical copies but each mode gets
            // its own "copy" to play with as the user pleases.
            for mode in modes {
                let dst2 = mode.rootFolder?
                    .appendingPathComponent(file.lastPathComponent)

                // Don't hardlink on itself.
                if dst1 == dst2 {
                    continue
                }

                do {
                    try fm.linkItem(at: dst1, to: dst2)
                }
                catch {
                    print("[\(String(describing: type(of: self)))] Error while hard linking file \"\(dst1!.path)\" to \"\(dst2!.path)\": \(error.localizedDescription)")
                }
            }
        }

        if needsUpdate {
            NotificationCenter.default.post(name: .reloadFromDisk, object: nil)
        }
    }


    // MARK: Private Methods

    private func endBackgroundTask() {
        guard backgroundTaskId != .invalid else {
            return
        }

        unCenter.removeDeliveredNotifications(withIdentifiers: [Self.unWarningId])
        unCenter.removePendingNotificationRequests(withIdentifiers: [Self.unWarningId])

        UIApplication.shared.endBackgroundTask(backgroundTaskId)
        backgroundTaskId = .invalid
    }

    /**
     Ask the user for permission to show notifications after a delay of 2 seconds.
     */
    private func askNotifications() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            var options: UNAuthorizationOptions = [.alert, .sound]

            options.update(with: .criticalAlert)

            self?.unCenter.requestAuthorization(options: options) { granted, error in
                print("[\(String(describing: type(of: self)))] UNUserNotificationCenter#requestAuthorization granted=\(granted), error=\(String(describing: error))")
            }
        }
    }

    /**
     Notify the user that they should return to the app immediately.
     */
    private func notifyUserBeforeEnd() {
        let content = warningNotificationContent
        content.sound = .defaultCritical

        if #available(iOS 15.0, *) {
            content.relevanceScore = 1
            content.interruptionLevel = .timeSensitive
        }

        unCenter.add(UNNotificationRequest(
            identifier: Self.unWarningId, content: content, trigger: nil))
    }
}
