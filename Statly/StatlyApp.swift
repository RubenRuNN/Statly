//
//  StatlyApp.swift
//  Statly
//
//  Created by Ruben Marques on 24/01/2026.
//

import SwiftUI

@main
struct StatlyApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ConfigurationListView()
                    .tabItem {
                        Label("Widgets", systemImage: "rectangle.grid.2x2")
                    }

                DocumentationView()
                    .tabItem {
                        Label("Docs", systemImage: "doc.text")
                    }
                
                SubscriptionView()
                    .tabItem {
                        Label("Subscription", systemImage: "crown")
                    }
            }
            .tint(.accentColor)
            .task {
                await subscriptionManager.checkSubscriptionStatus()
            }
        }
    }
}
