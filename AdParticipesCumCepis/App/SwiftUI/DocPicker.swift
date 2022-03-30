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

    public let type: UTType

    public let add: ([File]) -> Void

    public let completion: (() -> Void)?


    public init(type: UTType, _ add: @escaping ([File]) -> Void, _ completion: (() -> Void)? = nil) {
        self.type = type
        self.add = add
        self.completion = completion
    }


    public func makeUIViewController(context: Context) -> some UIViewController {
        UIDocumentPickerViewController(forOpeningContentTypes: [type], asCopy: false)
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let vc = uiViewController as? UIDocumentPickerViewController else {
            return
        }

        vc.delegate = context.coordinator
        vc.allowsMultipleSelection = true
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(add, completion)
    }


    open class Coordinator: NSObject, UIDocumentPickerDelegate {

        public let add: ([File]) -> Void

        public let completion: (() -> Void)?


        public init(_ add: @escaping ([File]) -> Void, _ completion: (() -> Void)?) {
            self.add = add
            self.completion = completion

            super.init()
        }


        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard urls.count > 0 else {
                return
            }

            add(urls.map({ Document($0) }))
        }


        deinit {
            completion?()
        }
    }
}
