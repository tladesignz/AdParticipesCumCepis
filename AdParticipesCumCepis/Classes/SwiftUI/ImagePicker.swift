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

    public let vc = TLPhotosPickerViewController()

//    public let sourceView: some View

    public let add: ([Asset]) -> Void

    public func makeUIViewController(context: Context) -> some UIViewController {
        vc
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(vc, add)
    }

    public class Coordinator: TLPhotosPickerViewControllerDelegate {

        let add: ([Asset]) -> Void

        init(_ vc: TLPhotosPickerViewController, _ add: @escaping ([Asset]) -> Void) {
            self.add = add

            vc.delegate = self
//            vc.popoverPresentationController?.sourceRect = sourceView
        }

        public func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
            add(withTLPHAssets.map({ Asset($0) }))

            return true
        }
    }
}
