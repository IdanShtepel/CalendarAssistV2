//
//  CalendarAssistV2App.swift
//  CalendarAssistV2
//
//  Created by Idan Shtepel on 8/13/25.
//

import SwiftUI
import GoogleSignIn

@main
struct CalendarAssistV2App: App {
    @StateObject private var googleCalendarService = GoogleCalendarService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    googleCalendarService.configure()
                }
                .onOpenURL { url in
                    _ = googleCalendarService.handleSignInURL(url)
                }
        }
    }
}
