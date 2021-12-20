//
//  ShowQrActivity.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 26.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import SwiftUI

/**
 Activity for `UIActivityViewController` to display a string as QR code.
 */
public class ShowQrActivity: UIActivity {
    
    private var qrCode: String?
    
    public override var activityTitle: String? {
        get {
            return NSLocalizedString("QR Code", comment: "")
        }
    }
    
    public override var activityType: UIActivity.ActivityType? {
        get {
            return ActivityType("\(Bundle.main.displayName)_ActivityTypeQrCode")
        }
    }

    public override var activityImage: UIImage? {
        get {
            return UIImage(systemName: "qrcode")
        }
    }
    
    public override var activityViewController: UIViewController? {
        get {
            let vc = UIHostingController(rootView: QrView(qrCode: qrCode ?? ""))

            let navC = UINavigationController(rootViewController: vc)
            navC.modalPresentationStyle = .formSheet

            vc.rootView.dismiss = { [weak navC] in
                navC?.dismiss(animated: true)
            }

            return navC
        }
    }

    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        if let item = activityItems.first {
            return item is String || item is URL
        }
        
        return false
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        if let item = activityItems.first {
            if let item = item as? String {
                qrCode = item
            }
            else if let item = item as? URL {
                qrCode = item.absoluteString
            }
        }
    }
}
