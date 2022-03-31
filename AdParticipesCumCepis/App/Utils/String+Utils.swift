//
//  String+Utils.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 31.03.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

extension String {

    var attributedMarkdownString: AttributedString {
        return (try? AttributedString(markdown: self)) ?? AttributedString(self)
    }
}
