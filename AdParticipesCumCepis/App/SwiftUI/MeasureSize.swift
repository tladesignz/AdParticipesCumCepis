//
//  MeasureSize.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 21.04.22.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {

    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    }
}

struct MeasureSizeModifier: ViewModifier {

    func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        })
    }
}

extension View {

    func measureSize(perform action: @escaping (CGSize) -> Void) -> some View {
        modifier(MeasureSizeModifier())
            .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}
