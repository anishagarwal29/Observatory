//
//  ObservatoryApp.swift
//  Observatory
//
//  Created by Anish Agarwal on 22/1/26.
//

import SwiftUI

@main
struct ObservatoryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("Observatory")
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
