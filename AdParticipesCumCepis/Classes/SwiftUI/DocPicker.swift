//
//  DocPicker.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

public struct DocPicker: UIViewControllerRepresentable {

    public let vc = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)

    public let add: ([File]) -> Void

    public func makeUIViewController(context: Context) -> some UIViewController {
        vc
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(vc, add)
    }

    public class Coordinator: NSObject, UIDocumentPickerDelegate {

        let add: ([File]) -> Void

        init(_ vc: UIDocumentPickerViewController, _ add: @escaping ([File]) -> Void) {
            self.add = add

            super.init()

            vc.delegate = self
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard urls.count > 0 else {
                return
            }

            add(urls.map({ File($0) }))
        }
    }
}
