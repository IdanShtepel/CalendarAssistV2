import SwiftUI
import Foundation
import GoogleSignIn

@MainActor
class GoogleCalendarService: ObservableObject {
    static let shared = GoogleCalendarService()
    
    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var isLoading = false
    
    private init() {
        checkSignInStatus()
    }
    
    // MARK: - Configuration
    func configure() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Error: GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        // Log the configuration for debugging
        if let reversedClientId = plist["REVERSED_CLIENT_ID"] as? String {
            print("Configuring with CLIENT_ID: \(clientId)")
            print("Expected URL scheme: \(reversedClientId)")
        }
        
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    // MARK: - Sign In/Out
    func signIn() async {
        print("🔐 Starting Google Sign-In process...")
        isLoading = true
        
        // Check if Google Sign-In is properly configured
        guard GIDSignIn.sharedInstance.configuration != nil else {
            print("❌ Google Sign-In not configured")
            isLoading = false
            AppState.shared.showErrorMessage("Google Sign-In not configured. Please check GoogleService-Info.plist")
            return
        }
        
        do {
            // Get the presenting view controller with better error handling
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            guard let windowScene = windowScene else {
                print("❌ No window scene found")
                isLoading = false
                AppState.shared.showErrorMessage("Cannot access app window")
                return
            }
            
            let presentingViewController = windowScene.windows.first?.rootViewController
            guard let presentingViewController = presentingViewController else {
                print("❌ No presenting view controller found")
                isLoading = false
                AppState.shared.showErrorMessage("Cannot present sign-in view")
                return
            }
            
            print("✅ Presenting view controller found: \(type(of: presentingViewController))")
            print("🚀 Initiating Google Sign-In...")
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            print("✅ Google Sign-In successful!")
            print("👤 User: \(user.profile?.email ?? "No email")")
            
            // Request additional scopes for Calendar access
            let additionalScopes = ["https://www.googleapis.com/auth/calendar"]
            let hasGrantedScopes = user.grantedScopes?.contains { scope in
                additionalScopes.contains(scope)
            } ?? false
            
            if !hasGrantedScopes {
                print("📋 Requesting calendar permissions...")
                try await user.addScopes(additionalScopes, presenting: presentingViewController)
                print("✅ Calendar permissions granted")
            }
            
            isSignedIn = true
            userEmail = user.profile?.email
            isLoading = false
            
            AppState.shared.showSuccessMessage("Successfully signed in to Google Calendar")
            
        } catch {
            print("❌ Google Sign-In error: \(error)")
            isLoading = false
            AppState.shared.showErrorMessage("Failed to sign in to Google Calendar: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userEmail = nil
        AppState.shared.showSuccessMessage("Signed out of Google Calendar")
    }
    
    // MARK: - Calendar Operations
    func fetchCalendarEvents() async -> [GoogleCalendarEvent] {
        guard isSignedIn,
              let user = GIDSignIn.sharedInstance.currentUser else {
            print("Error: User not signed in")
            return []
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Basic Google Calendar API call structure
        let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return []
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Error: Invalid response from Google Calendar API")
                return []
            }
            
            // Parse the response here - for now return empty array
            print("Calendar events data received: \(data.count) bytes")
            return []
        } catch {
            print("Error fetching calendar events: \(error)")
            return []
        }
    }
    
    func createCalendarEvent(_ event: Event) async -> Bool {
        guard isSignedIn,
              let user = GIDSignIn.sharedInstance.currentUser else {
            print("Error: User not signed in")
            return false
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Basic Google Calendar API event creation
        let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return false
        }
        
        let formatter = ISO8601DateFormatter()
        let endTime = event.time.addingTimeInterval(3600) // 1 hour default
        
        let eventData: [String: Any] = [
            "summary": event.title,
            "description": "Created from Calendar Assistant",
            "start": [
                "dateTime": formatter.string(from: event.time),
                "timeZone": TimeZone.current.identifier
            ],
            "end": [
                "dateTime": formatter.string(from: endTime),
                "timeZone": TimeZone.current.identifier
            ],
            "location": event.location
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventData)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               200...299 ~= httpResponse.statusCode {
                AppState.shared.showSuccessMessage("Event created in Google Calendar")
                return true
            } else {
                AppState.shared.showErrorMessage("Failed to create event in Google Calendar")
                return false
            }
            
        } catch {
            print("Error creating calendar event: \(error)")
            AppState.shared.showErrorMessage("Failed to create event in Google Calendar")
            return false
        }
    }

    // Create a calendar event with explicit fields (uses end time and all-day when provided)
    func createCalendarEvent(title: String,
                             start: Date,
                             end: Date,
                             location: String? = nil,
                             description: String? = nil,
                             isAllDay: Bool = false) async -> Bool {
        guard isSignedIn,
              let user = GIDSignIn.sharedInstance.currentUser else {
            print("Error: User not signed in")
            return false
        }
        let accessToken = user.accessToken.tokenString

        let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return false
        }

        // Formatters for date/time
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.timeZone = TimeZone.current
        dayFormatter.dateFormat = "yyyy-MM-dd"

        var startDict: [String: Any]
        var endDict: [String: Any]
        if isAllDay {
            startDict = ["date": dayFormatter.string(from: start)]
            // Google expects end date to be the day AFTER for all-day events
            let endDay = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
            endDict = ["date": dayFormatter.string(from: endDay)]
        } else {
            startDict = [
                "dateTime": isoFormatter.string(from: start),
                "timeZone": TimeZone.current.identifier
            ]
            endDict = [
                "dateTime": isoFormatter.string(from: end),
                "timeZone": TimeZone.current.identifier
            ]
        }

        var eventData: [String: Any] = [
            "summary": title,
            "start": startDict,
            "end": endDict
        ]
        if let description = description, !description.isEmpty {
            eventData["description"] = description
        }
        if let location = location, !location.isEmpty {
            eventData["location"] = location
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventData)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode {
                AppState.shared.showSuccessMessage("Event created in Google Calendar")
                return true
            } else {
                AppState.shared.showErrorMessage("Failed to create event in Google Calendar")
                return false
            }
        } catch {
            print("Error creating calendar event: \(error)")
            AppState.shared.showErrorMessage("Failed to create event in Google Calendar")
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func checkSignInStatus() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            isSignedIn = !user.accessToken.tokenString.isEmpty
            userEmail = user.profile?.email
        }
    }
    
    func handleSignInURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - Google Calendar Event Model
struct GoogleCalendarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let location: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title = "summary"
        case description
        case startTime = "start"
        case endTime = "end"
        case location
    }
}

// MARK: - Extensions
extension GoogleCalendarService {
    var statusText: String {
        if isLoading {
            return "Connecting..."
        } else if isSignedIn {
            return "Connected to \(userEmail ?? "Google Calendar")"
        } else {
            return "Not connected"
        }
    }
    
    var statusColor: Color {
        if isLoading {
            return .orange
        } else if isSignedIn {
            return .green
        } else {
            return .secondary
        }
    }
}