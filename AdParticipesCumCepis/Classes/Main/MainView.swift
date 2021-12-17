//
//  MainView.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 17.12.21.
//

import SwiftUI

public struct MainView: View {

    public var body: some View {
        // TODO: Fix UI bug, where stuff is shining through after drawer open/closing.
        TabView {
            NavigationView {
                Router.share()
            }
            .tabItem {
                Image(systemName: "paperplane")
                Text(NSLocalizedString("Share", comment: ""))
            }

            NavigationView {
                Router.host()
            }
            .tabItem {
                Image(systemName: "globe")
                Text(NSLocalizedString("Website", comment: ""))
            }
        }
    }

    public init() {
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
