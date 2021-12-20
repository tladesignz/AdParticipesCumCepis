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

    public let add: ([Asset]) -> Void


    public func makeUIViewController(context: Context) -> some UIViewController {
        let vc = TLPhotosPickerViewController()
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
