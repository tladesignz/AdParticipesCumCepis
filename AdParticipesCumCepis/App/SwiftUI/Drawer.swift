//
//  Drawer.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 16.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//
// Adapted from: https://swiftwithmajid.com/2019/12/11/building-bottom-sheet-in-swiftui/
//

import SwiftUI

public struct Drawer<Content: View>: View {

    @Binding public var open: Bool

    public let maxHeight: CGFloat
    public let minHeight: CGFloat
    public let snapDistance: CGFloat = 48
    public let content: Content

    private var indicator: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary)
            .frame(width: 80, height: 6)
    }

    @GestureState private var translation: CGFloat = 0

    init(open: Binding<Bool>, minHeight: CGFloat, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
        _open = open
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            let maxHeight = min(maxHeight, geometry.size.height)

            VStack(spacing: 0) {
                indicator
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                content
            }
            .frame(width: geometry.size.width, height: maxHeight, alignment: .top)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: offset(maxHeight) + translation)
            .animation(.interactiveSpring())
            .gesture(DragGesture().updating($translation, body: { value, state, _ in
                state = value.translation.height
            }).onEnded({ value in
                guard abs(value.translation.height) > snapDistance else {
                    return
                }

                open = value.translation.height < 0
            }))
        }
        .shadow(color: .init("Shadow", bundle: .adParticipesCumCepis), radius: 12, x: 0, y: -12)
    }

    private func offset(_ maxHeight: CGFloat) -> CGFloat {
        return open ? 0 : maxHeight - minHeight
    }
}
