//
//  HostModel.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

open class HostModel: ShareModel {

    open override var title: String {
        NSLocalizedString("Host", comment: "")
    }

    open override var addressLbTextWithPrivateKey: AttributedString {
        String(format: NSLocalizedString(
            "%1$@Anyone%1$@ with this address and private key can %1$@visit your website%1$@ using the %1$@Tor Browser%1$@:",
            comment: "%1$@ == '**' (Markdown!)"), "**")
        .attributedMarkdownString
    }

    open override var addressLbTextNoPrivateKey: AttributedString {
        String(format: NSLocalizedString(
            "%1$@Anyone%1$@ with this address can %1$@visit your website%1$@ using the %1$@Tor Browser%1$@:",
            comment: "%1$@ == '**' (Markdown!)"), "**")
        .attributedMarkdownString
    }

    open override var stopSharingAfterSendLb: String {
        NSLocalizedString(
            "Don't send Content Security Policy header (allows your website to use third-party resources)",
            comment: "")
    }

    open override var stopSharingAfterSendInitialValue: Bool {
        false
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
