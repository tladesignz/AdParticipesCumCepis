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

    public let minHeight: CGFloat
    public let snapDistance: CGFloat = 48
    public let content: Content

    private var indicator: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary)
            .frame(width: 80, height: 6)
    }

    @GestureState private var translation: CGFloat = 0

    @State private var contentSize = CGSize.zero

    init(open: Binding<Bool>, minHeight: CGFloat, @ViewBuilder content: () -> Content) {
        _open = open
        self.minHeight = minHeight
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                indicator
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                content
                    .padding(.bottom, 16)
            }
            .measureSize { contentSize = $0 }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .offset(y: geometry.size.height - (open ? contentSize.height : minHeight) + translation)
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
        .shadow(color: .init("Shadow", bundle: .adParticipesCumCepis), radius: 3, x: 0, y: -3)
    }
}
