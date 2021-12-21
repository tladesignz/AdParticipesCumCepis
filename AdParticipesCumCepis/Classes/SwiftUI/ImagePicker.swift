//
//  ImagePicker.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI
import TLPhotoPicker

public struct ImagePicker: UIViewControllerRepresentable {

    public static var configuration: TLPhotosPickerConfigure = {
        var conf = TLPhotosPickerConfigure()
        conf.cancelTitle = NSLocalizedString("Cancel", comment: "")
        conf.doneTitle = NSLocalizedString("Done", comment: "")
        conf.emptyMessage = NSLocalizedString("No albums", comment: "")
        conf.tapHereToChange = NSLocalizedString("Tap here to change", comment: "")

        return conf
    }()

    public let add: ([Asset]) -> Void


    public func makeUIViewController(context: Context) -> some UIViewController {
        let vc = TLPhotosPickerViewController()
        vc.configure = Self.configuration
        vc.delegate = context.coordinator

        return vc
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        (uiViewController as? TLPhotosPickerViewController)?.delegate = context.coordinator
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(add)
    }


    open class Coordinator: TLPhotosPickerViewControllerDelegate {

        let add: ([Asset]) -> Void

        init(_ add: @escaping ([Asset]) -> Void) {
            self.add = add
        }

        public func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
            add(withTLPHAssets.map({ Asset($0) }))

            return true
        }
    }
}
