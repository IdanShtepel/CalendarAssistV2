# CalendarAssistV2 📅

An intelligent iOS calendar management app powered by AI that helps you organize your schedule, create events naturally, and manage your time more effectively.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 🤖 AI-Powered Event Creation
- **Natural Language Processing**: Create events using conversational language
- **Smart Event Classification**: Automatically categorize events (work, personal, friends, etc.)
- **AI Assistant Chat**: Get help with scheduling, reminders, and calendar management
- **Multiple LLM Support**: Choose from Hugging Face (free) or OpenRouter (premium models)

### 📱 Core Calendar Features
- **Google Calendar Integration**: Sync with your existing Google Calendar
- **Event Management**: Create, edit, and delete events with rich details
- **Today's Agenda**: Quick overview of your daily schedule
- **Search & Filter**: Find events quickly with powerful search
- **Dark Mode**: Beautiful dark and light themes with smooth transitions

### ✅ Todo Management
- **Smart Todo Creation**: Natural language todo parsing
- **Priority Management**: Organize tasks by importance
- **Bulk Actions**: Select and manage multiple todos at once
- **Progress Tracking**: Visual indicators for task completion

### 🎨 Modern UI/UX
- **Responsive Design**: Optimized for all iPhone sizes
- **Smooth Animations**: Delightful micro-interactions
- **Accessibility**: Full VoiceOver and accessibility support
- **Customizable Colors**: Personalize your app experience

## 🚀 Getting Started

### Prerequisites
- iOS 15.0 or later
- Xcode 14.0 or later
- Swift 5.0 or later

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/IdanShtepel/CalendarAssistV2.git
   cd CalendarAssistV2
   ```

2. **Open in Xcode**
   ```bash
   open CalendarAssistV2.xcodeproj
   ```

3. **Configure Google Calendar**
   - Add your `GoogleService-Info.plist` to the project
   - Enable Google Calendar API in your Google Cloud Console
   - Configure OAuth credentials

4. **Set up AI Services** (Optional but recommended)
   - **Hugging Face** (Free): Get API key from [huggingface.co](https://huggingface.co)
   - **OpenRouter** (Premium): Get API key from [openrouter.ai](https://openrouter.ai)

5. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

## 🔧 Configuration

### Google Calendar Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing one
3. Enable Google Calendar API
4. Create OAuth 2.0 credentials
5. Download `GoogleService-Info.plist` and add to project

### AI Service Configuration
The app supports two AI providers:

#### Hugging Face (Free)
1. Visit [huggingface.co](https://huggingface.co)
2. Create an account
3. Go to Settings → Access Tokens
4. Create a 'Read' token
5. Enter the token in app settings

#### OpenRouter (Premium Models)
1. Visit [openrouter.ai](https://openrouter.ai)
2. Create an account
3. Go to Keys section
4. Create new API key
5. Enter the key in app settings

### Available AI Models
- **Claude 3 Haiku** - Fast and efficient
- **Claude 3 Sonnet** - Balanced performance
- **GPT-3.5 Turbo** - Popular choice
- **GPT-4 Turbo** - Most capable
- **Llama 3 8B/70B** - Open source options
- **Gemini Flash 1.5** - Google's model

## 📱 Usage

### Creating Events
1. **Tap the "+" button** on the bottom navigation
2. **Use natural language** like:
   - "Meeting with John tomorrow at 2 PM"
   - "Lunch with Sarah next Friday at noon"
   - "Doctor appointment next Tuesday at 3:30 PM"
3. **Review and confirm** the AI-generated event details
4. **Save** to add to your calendar

### Managing Todos
1. **Navigate to the Todo tab**
2. **Tap "+" to create new todo**
3. **Use natural language** like:
   - "Buy groceries tomorrow"
   - "Finish project report by Friday"
   - "Call mom this weekend"
4. **Set priorities and due dates**
5. **Mark as complete** when done

### AI Assistant Chat
1. **Tap "Ask Assistant"** on the home screen
2. **Ask questions** like:
   - "What's my schedule for tomorrow?"
   - "Do I have any conflicts this week?"
   - "Suggest a good time for a 1-hour meeting"
3. **Get intelligent responses** and suggestions

## 🏗️ Architecture

### Project Structure
```
CalendarAssistV2/
├── Components/          # Reusable UI components
├── Models/             # Data models (Event, TodoItem, etc.)
├── Services/           # Business logic and API services
├── Views/              # Main app views
├── Navigation/         # Navigation components
├── Utilities/          # Helper utilities
└── Debug/             # Debug tools and utilities
```

### Key Services
- **`AssistantService`**: AI chat and conversation management
- **`GoogleCalendarService`**: Google Calendar integration
- **`LLMService`**: AI model abstraction layer
- **`TodoService`**: Todo management and persistence
- **`CategoryClassificationService`**: Smart event categorization

### Design System
The app uses a comprehensive design system with:
- **Typography**: Consistent font scales and weights
- **Colors**: Adaptive color schemes for light/dark mode
- **Spacing**: Standardized spacing values
- **Components**: Reusable UI components
- **Animations**: Smooth transitions and micro-interactions

## 🔒 Security & Privacy

- **No hardcoded API keys** - All credentials stored securely in UserDefaults
- **Local data storage** - Your data stays on your device
- **Secure API communication** - All external requests use HTTPS
- **Privacy-focused** - No data collection or tracking

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Calendar API** for calendar integration
- **Hugging Face** for free AI models
- **OpenRouter** for premium AI model access
- **SwiftUI** for the modern UI framework
- **AppAuth** for OAuth authentication



---

**Made with ❤️ for better time management**

*CalendarAssistV2 - Your intelligent calendar companion*
