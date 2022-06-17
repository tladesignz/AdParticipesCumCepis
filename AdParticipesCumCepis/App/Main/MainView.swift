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
                Text(NSLocalizedString("Host", comment: ""))
            }
        }
        .onAppear {
            if #available(iOS 15.0, *) {
                let a = UITabBarAppearance()
                a.configureWithOpaqueBackground()

                UITabBar.appearance().scrollEdgeAppearance = a
            }

            UITableView.appearance().backgroundColor = .systemBackground
        }
        .onChange(of: scenePhase) { newPhase in
            BaseAppDelegate.shared?.changeOf(scenePhase: newPhase)
        }
        .onOpenURL { url in
            guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return
            }

            if urlc.path == "token-callback" {
                if let token = urlc.queryItems?.first(where: { $0.name == "token" })?.value {
                    OrbotManager.shared.received(token: token)
                }
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
