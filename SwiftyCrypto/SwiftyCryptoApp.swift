//
//  SwiftyCryptoApp.swift
//  SwiftyCrypto
//
//  Created by varunbhalla19 on 24/12/22.
//

import SwiftUI

@main
struct SwiftyCryptoApp: App {
    
    @State var showLaunchView = true
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(.theme.accent)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(.theme.accent)]
        UINavigationBar.appearance().tintColor = UIColor(.theme.accent)
        UITableView.appearance().backgroundColor = UIColor(.theme.background)
    }
    
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                NavigationView {
                    HomeView()
                        .navigationBarHidden(true)
                }
                .navigationViewStyle(.stack)
                .environmentObject(homeViewModel)
                
                ZStack {
                    if showLaunchView {
                        LaunchView(show: $showLaunchView)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }.zIndex(2)
            }
        }
    }
}
