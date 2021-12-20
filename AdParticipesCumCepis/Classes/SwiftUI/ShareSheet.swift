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

    public let completion: () -> ()


    public func makeUIViewController(context: Context) -> some UIViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: [ShowQrActivity()])
        vc.presentationController?.delegate = context.coordinator

        return vc
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        (uiViewController as? UIActivityViewController)?.presentationController?.delegate = context.coordinator
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(completion)
    }


    open class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {

        public let completion: () -> ()

        public init(_ completion: @escaping () -> ()) {
            self.completion = completion

            super.init()
        }

        deinit {
            // All the callbacks won't be called, because the coordinator will
            // get disconnected too early.
            // But it must get deinited, so we can achieve this anyway!

            completion()
        }
    }
}
