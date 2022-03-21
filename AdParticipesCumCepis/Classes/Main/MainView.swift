//
//  MainView.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 17.12.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import SwiftUI

public struct MainView: View {

    @Environment(\.scenePhase)
    var scenePhase

    public var body: some View {
        TabView {
            NavigationView {
                ShareView(ShareModel())
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: "paperplane")
                Text(NSLocalizedString("Share", comment: ""))
            }

            NavigationView {
                ShareView(HostModel())
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Image(systemName: "globe")
                Text(NSLocalizedString("Website", comment: ""))
            }
        }
        .onAppear {
            if #available(iOS 15.0, *) {
                let a = UITabBarAppearance()
                a.configureWithOpaqueBackground()

                UITabBar.appearance().scrollEdgeAppearance = a
            }
        }
        .onChange(of: scenePhase) { newPhase in
            BaseAppDelegate.shared?.changeOf(scenePhase: newPhase)
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
