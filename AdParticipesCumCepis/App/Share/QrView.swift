//
//  QrView.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 20.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI

public struct QrView: View {

    public var qrCode: String

    public var dismiss: (() -> Void)? = nil

    public var body: some View {
        VStack {
            GeometryReader { geo in
                if let image = UIImage.qrCode(qrCode, geo.size) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: .infinity)
                }
                else {
                    Image(systemName: "nosign")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: .infinity)
                }
            }

            Text(qrCode)
        }
        .padding()
        .navigationTitle(NSLocalizedString("QR Code", comment: ""))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    dismiss?()
                } label: {
                    if #available(iOS 15.0, *) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .symbolRenderingMode(.hierarchical)
                            .tint(.secondary)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
    }
}

struct QrView_Previews: PreviewProvider {
    static var previews: some View {
        QrView(qrCode: "http://example.com/")
    }
}
