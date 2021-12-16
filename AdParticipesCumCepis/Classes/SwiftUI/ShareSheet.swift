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

    public let completed: (() -> Void)?

    public func makeUIViewController(context: Context) -> some UIViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: [ShowQrActivity()])

        vc.presentationController?.delegate = makeCoordinator()

        return vc
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(completed ?? {})
    }

    public class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {

        let completed: () -> Void

        public init(_ completed: @escaping () -> Void) {
            self.completed = completed

            super.init()
        }

        public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            completed()
        }
    }
}
