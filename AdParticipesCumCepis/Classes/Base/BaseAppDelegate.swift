//
//  AppDelegate.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 05.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import UserNotifications

open class BaseAppDelegate: UIResponder, UIApplicationDelegate {

    public static let unWarningId = "warning-return-to-app"


    private var backgroundTaskId = UIBackgroundTaskIdentifier.invalid

    private var unCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }


    open lazy var warningNotificationContent: UNMutableNotificationContent = {
        let content = UNMutableNotificationContent()

        content.title = String(
            format: NSLocalizedString("%@ will be stopped shortly", comment: ""),
            Bundle.main.displayName)

        content.body = String(
            format: NSLocalizedString("Please return to %@ immediately to continue sharing your content!", comment: ""),
            Bundle.main.displayName)

        content.sound = .default

        return content
    }()


    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        askNotifications()

        return true
    }

    open func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

        guard Router.webServer?.running ?? false else {
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
    }

    open func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

        endBackgroundTask()

        if Router.webServer?.running ?? false {
            Dimmer.shared.start()
        }
    }

    open func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        endBackgroundTask()
    }

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
