//
//  Status.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI

public struct Status: View {

    let color: Color

    let text: String

    public init(_ state: ShareModel.State, _ progress: Double, _ error: Error?) {
        if let error = error {
            color = .red
            text = error.localizedDescription
        }
        else {
            switch state {
            case .stopped:
                color = .gray
                text = NSLocalizedString("Ready", comment: "")

            case .starting:
                let nf = NumberFormatter()
                nf.numberStyle = .percent
                nf.maximumFractionDigits = 0

                color = .orange
                text = String(format: NSLocalizedString("Starting… %@", comment: ""), nf.string(for: progress) ?? "0 %")

            case .running:
                color = .green
                text = NSLocalizedString("Sharing", comment: "")
            }
        }
    }

    public var body: some View {
        HStack {
            Circle()
                .frame(width: 16, height: 16)
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 22))
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
