//
//  DHCharListHostApp.swift
//  DHCharListHost
//
//  Created by Артеменко Андрей Александрович on 07.03.2026.
//

import SwiftUI
import DHCharList

@main
struct DHCharListHostApp: App {
    var body: some Scene {
        WindowGroup {
            DHCharListAppShell(container: .live())
        }
    }
}
