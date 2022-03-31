//
//  Formatters.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 31.03.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

open class Formatter {

    public static let date: DateFormatter = {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.dateStyle = .medium
        f.timeStyle = .none

        return f
    }()

    public static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 0

        return f
    }()

    public static func format(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }

        return self.date.string(from: date)
    }

    public static func format(filesize: Int64?) -> String {
        return ByteCountFormatter.string(fromByteCount: filesize ?? 0, countStyle: .file)
    }

    public static func format(percent: Double) -> String {
        return self.percent.string(for: percent) ?? "0 %"
    }
}
