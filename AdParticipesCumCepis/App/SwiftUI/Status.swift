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

    public init(_ state: ShareModel.State, _ progress: Double, _ error: Error?, _ runningText: String) {
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
                color = .orange
                text = String(format: NSLocalizedString("Starting… %@", comment: ""), Formatter.format(percent: progress))

            case .running:
                color = .green
                text = runningText
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
        .padding([.leading, .trailing, .bottom])
        .padding(.top, 8)
    }
}
