//
//  ShareSheet.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI

public struct ShareSheet: UIViewControllerRepresentable {

    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> some UIViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: [ShowQrActivity()])
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
