//
//  HostModel.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

open class HostModel: ShareModel {

    open override var titleText: String {
        NSLocalizedString("Host", comment: "")
    }

    open override var runningText: String {
        NSLocalizedString("Hosting", comment: "")
    }

    open override var addressLbTextWithPrivateText: AttributedString {
        String(format: NSLocalizedString(
            "%1$@Anyone%1$@ with this address and private key can %1$@visit your website%1$@ using the %1$@Tor Browser%1$@:",
            comment: "%1$@ == '**' (Markdown!)"), "**")
        .attributedMarkdownString
    }

    open override var addressLbTextNoPrivateText: AttributedString {
        String(format: NSLocalizedString(
            "%1$@Anyone%1$@ with this address can %1$@visit your website%1$@ using the %1$@Tor Browser%1$@:",
            comment: "%1$@ == '**' (Markdown!)"), "**")
        .attributedMarkdownString
    }

    open override var stopSharingAfterSendText: String {
        NSLocalizedString(
            "Permit third-party resources (don't send Content Security Policy header)",
            comment: "")
    }

    open override var stopSharingAfterSendInitialValue: Bool {
        false
    }

    open override var startButtonText: String {
        NSLocalizedString("Start Hosting", comment: "")
    }

    open override var stopButtonText: String {
        NSLocalizedString("Stop Hosting", comment: "")
    }


    // MARK: WebServerDelegate

    open override var mode: WebServer.Mode {
        return .host
    }

    open override var templateName: String {
        return "listing"
    }

    open override var useCsp: Bool {
        stopSharingAfterSend
    }
}
