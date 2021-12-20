//
//  MainView.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 17.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI

public struct MainView: View {

    public var body: some View {
        // TODO: Fix UI bug, where stuff is shining through after drawer open/closing.
//        TabView {
            NavigationView {
                ShareView(ShareModel())
            }
            .navigationViewStyle(.stack)
//            .tabItem {
//                Image(systemName: "paperplane")
//                Text(NSLocalizedString("Share", comment: ""))
//            }
//
//            NavigationView {
//                ShareView(HostModel())
//            }
//            .navigationViewStyle(.stack)
//            .tabItem {
//                Image(systemName: "globe")
//                Text(NSLocalizedString("Website", comment: ""))
//            }
//        }
    }

    public init() {
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
