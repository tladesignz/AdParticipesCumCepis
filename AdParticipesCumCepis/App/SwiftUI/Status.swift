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

    let progress: Double?

    public init(_ state: ShareModel.State, _ progress: Double, _ error: Error?, _ runningText: String) {
        if let error = error {
            color = .red
            text = error.localizedDescription
            self.progress = nil
        }
        else {
            switch state {
            case .stopped:
                color = .gray
                text = NSLocalizedString("Ready", comment: "")
                self.progress = nil

            case .starting:
                color = .orange
                text = NSLocalizedString("Starting…", comment: "")
                self.progress = progress

            case .running:
                color = .green
                text = runningText
                self.progress = nil
            }
        }
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle()
                    .frame(width: 16, height: 16)
                    .foregroundColor(color)

                Text(text)
                    .font(.system(size: 22))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.leading, .trailing])
            .padding(.top, 8)
            .padding(.bottom, 4)

            if let progress = progress {
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
                    .scaleEffect(x: 1, y: 0.25, anchor: .center)
            }
            else {
                Divider()
                    .padding(.top, 4)
            }
        }
    }
}
