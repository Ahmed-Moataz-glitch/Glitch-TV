<div align="center">

# ⚡ Glitch TV

**A modern, feature-rich cross-platform media streaming application for Live TV, Radio Broadcasts, and Podcasts with offline playback support.**

Built with **Flutter**, designed using **Clean Architecture**, and powered by **BLoC / Cubit** for reactive state management.

---

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-blueviolet?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![BLoC](https://img.shields.io/badge/State%20Management-BLoC%20%2F%20Cubit-blue?style=for-the-badge)](https://bloclibrary.dev)
[![Hive](https://img.shields.io/badge/Storage-Hive%20DB-FFA000?style=for-the-badge&logo=hive&logoColor=white)](https://pub.dev/packages/hive)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-brightgreen?style=flat-square)]()
[![Localization](https://img.shields.io/badge/Language-English%20%7C%20%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9%20(RTL)-orange?style=flat-square)]()
[![Theme](https://img.shields.io/badge/Theme-Dark%20%7C%20Light%20%7C%20System-9cf?style=flat-square)]()

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
  - [Live TV Streaming & EPG](#-live-tv-streaming--epg-guide)
  - [Live Radio Broadcasting](#-live-radio-broadcasting)
  - [Podcasts & Offline Downloads](#-podcasts--offline-downloads)
  - [Favorites & Bookmarking](#-favorites--bookmarks)
  - [Adaptive Theming & UI/UX](#-adaptive-theming--responsive-ui)
  - [Localization & RTL Support](#-localization--rtl-support)
  - [Offline Resilience & Smart Caching](#-offline-resilience--caching)
- [Application Architecture](#-application-architecture)
- [Project Directory Structure](#-project-directory-structure)
- [Tech Stack & Dependencies](#-tech-stack--dependencies)
- [APIs & Data Sources](#-apis--data-sources)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation & Setup](#installation--setup)
  - [Running the App](#running-the-app)
- [Platform Specific Configuration](#-platform-specific-configuration)
  - [Android](#android)
  - [iOS](#ios)
- [Building for Production](#-building-for-production)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

---

## 🌟 Overview

**Glitch TV** is an all-in-one entertainment hub that unifies **Live Television**, **Live Radio**, and **On-Demand Podcasts** into a single, high-performance Flutter mobile application.

Engineered with production-grade architectural patterns, it delivers seamless HLS/DASH video playback with auto-failover, background audio service with lock-screen media controls, multi-language localization (with full RTL support), and a robust offline download manager for podcast episodes.

---

## 🚀 Key Features

### 📺 Live TV Streaming & EPG Guide
- **Multi-Protocol Playback**: High-performance video player powered by `awesome_video_player` (ExoPlayer & AVPlayer backend) supporting **HLS (`.m3u8`)**, **DASH (`.mpd`)**, and **SmoothStreaming (`.ism`)**.
- **Smart Web Fallback**: Dynamic fallback to embedded web views (`s_webview`) for YouTube feeds, web portals, and iframe streams.
- **Stream Health Watchdog**: Automatic 14-second stall watchdog, smart retry mechanism, and seamless multi-feed failover when alternative streams are available.
- **Custom Streaming Headers**: Injects custom `User-Agent` and `Referer` headers for reliable CDN playback.
- **Interactive TV Schedule (EPG)**: Real-time Electronic Program Guide with XML parsing displaying currently airing programs, progress bar, and upcoming shows for the day.

### 📻 Live Radio Broadcasting
- **Instant Radio Streaming**: Stream top Egyptian and international radio stations in real-time using `just_audio`.
- **ICY Metadata Extraction**: Extracts live stream metadata to display real-time track titles and show information.
- **Background Playback & Media Notification**: Persistent background playback using `just_audio_background` and `audio_service` with lock-screen and notification center controls.
- **Volume & Audio Control**: Dedicated volume level modal with quick-selection presets (Mute, 25%, 50%, 75%, 100%).
- **Social Sharing**: Share favorite stations and streams directly with friends via `share_plus`.

### 🎙️ Podcasts & Offline Downloads
- **Discover & Explore**: Browse curated categories (Technology, Business, Stories, Self Development, Comedy, and Classics) sourced via Apple iTunes Search API.
- **Dedicated Podcast Player**: Full playback controls, 10-second skip forward/backward, scrubber, and playback speed adjustment.
- **Offline Download Manager**:
  - Background HTTP stream downloading with real-time percentage progress.
  - MediaStore integration on Android to index downloaded episodes in public device storage.
  - Safe sanitization of audio file names and MIME format detection (`.mp3`, `.m4a`, `.aac`, `.wav`, `.ogg`).
  - Dedicated **Downloads Page** with storage consumption meter, offline episode player, and swipe-to-delete management.

### ⭐ Favorites & Bookmarks
- **Instant Bookmarking**: Bookmark favorite TV channels and radio stations with a single tap.
- **Persistent Local Storage**: Powered by high-speed NoSQL `Hive` database for instant startup retrieval without network latency.
- **Searchable Favorites**: Real-time filtering and search across saved channels.

### 🎨 Adaptive Theming & Responsive UI
- **Dual Theme Support**: Elegant deep purple Dark Mode (`#0F0A1A` scaffold, `#1C1230` card) and crisp Light Mode (`#F6F4FA` scaffold, `#FFFFFF` card) with System Default option.
- **Responsive Layouts**: Scaled across phone and tablet form factors via `flutter_screenutil`.
- **Micro-Animations & Visual Polish**: Shimmer loading skeletons, animated bottom navigation bar with active pill indicator, and Lottie animations.

### 🌐 Localization & RTL Support
- **Multi-Language**: Full native localization in **English** and **Arabic (العربية)**.
- **Dynamic RTL Layouts**: Automatic UI mirroring, font adjustments (Cairo typeface support), and bidirectional text rendering.

### 🔌 Offline Resilience & Caching
- **Multi-Tier API Caching**: `ApiCacheService` caches network responses in Hive with configurable TTL and stale-while-revalidate fallbacks.
- **Connectivity Detection**: `flutter_offline` monitors network transitions, showing an intuitive offline banner and quick-access button to downloaded media.

---

## 🏛️ Application Architecture

Glitch TV follows Uncle Bob's **Clean Architecture** principles combined with the **Repository Pattern** and **BLoC (Business Logic Component)**:

```
                  ┌─────────────────────────────────────┐
                  │          Presentation Layer         │
                  │  (Pages, Widgets, Cubits, States)   │
                  └──────────────────┬──────────────────┘
                                     │  uses
                                     ▼
                  ┌─────────────────────────────────────┐
                  │            Domain Layer             │
                  │   (Entities, UseCases, Repos ABI)   │
                  └──────────────────▲──────────────────┘
                                     │  implements
                                     │
                  ┌──────────────────┴──────────────────┐
                  │             Data Layer              │
                  │   (DTOs, Mappers, Repos, APIs)      │
                  └──────────────────┬──────────────────┘
                                     │  accesses
                                     ▼
                  ┌─────────────────────────────────────┐
                  │          Core / Infrastructure      │
                  │  (Network Client, Cache, Storage)   │
                  └─────────────────────────────────────┘
```

### Layer Responsibilities:
1. **Domain Layer**: Contains enterprise business rules, `UseCases`, and abstract repository contracts. It has zero external dependencies on Flutter or third-party packages.
2. **Data Layer**: Implements domain repository interfaces, manages remote REST APIs (`AppHttpClient`), local storage (`Hive`), and maps JSON DTOs to Domain Entities.
3. **Presentation Layer**: Built with `flutter_bloc` (Cubit). Manages UI states (`Initial`, `Loading`, `Success`, `Error`), handles user interactions, and renders responsive widgets.
4. **Core Layer**: Houses cross-cutting concerns including network caching, theme definitions, routing, constants, and shared UI components.

---

## 📂 Project Directory Structure

```plaintext
glitch_tv/
├── android/                   # Android native configuration & manifests
├── assets/                    # Static assets & animations
│   ├── images/                # App splash screen graphics
│   └── lottie/                # Lottie vector animation files
├── ios/                       # iOS native configuration & Info.plist
├── lib/
│   ├── core/                  # Core modules & shared utilities
│   │   ├── services/          # Low-level services (ApiCacheService, AppHttpClient)
│   │   ├── utils/             # Constants, Theme, Colors, Router, Toast, Assets
│   │   └── view/widgets/      # Shared UI wrappers (AppSection, OfflineWrapper)
│   ├── features/              # Feature-driven modular architecture
│   │   ├── channel_details/   # TV channel details, stream player & EPG guide
│   │   │   ├── data/          # APIs, DTOs, DataSource & Repo implementations
│   │   │   ├── domain/        # Entities, Repository interfaces & UseCases
│   │   │   └── presentation/  # Stream page, EPG widgets & ChannelStreamCubit
│   │   ├── downloads/         # Offline podcast downloads manager
│   │   │   ├── data/          # Downloaded episode DTOs & storage models
│   │   │   └── presentation/  # Downloads page & storage visualizer
│   │   ├── favorites/         # Favorite channels & bookmarks
│   │   │   ├── data/          # Hive local data source & repo
│   │   │   ├── domain/        # Get & Toggle favorites use cases
│   │   │   └── presentation/  # Favorites page & FavoritesCubit
│   │   ├── home/              # Main hub (TV, Radio, Podcasts tabs)
│   │   │   ├── data/          # Home APIs & multi-source data repository
│   │   │   ├── domain/        # Channel, Radio & Podcast use cases
│   │   │   └── presentation/  # Home page, tab views, swiper & HomeCubit
│   │   ├── podcast_details/   # Podcast episode list, audio player & downloader
│   │   │   ├── data/          # iTunes API, download service & repo
│   │   │   ├── domain/        # Fetch episodes use case
│   │   │   └── presentation/  # Podcast details, player & PodcastDetailsCubit
│   │   └── settings/          # App settings, language & theme customization
│   │       ├── data/          # SharedPreferences / Hive local data source
│   │       ├── domain/        # Settings repository contracts
│   │       └── presentation/  # Settings page & SettingsCubit
│   ├── l10n/                  # Localization ARB files (en, ar) & generated delegates
│   └── main.dart              # Application entry point & dependency initialization
├── pubspec.yaml               # Package dependencies & asset configuration
└── README.md                  # Project documentation
```

---

## 🛠️ Tech Stack & Dependencies

| Category | Package | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) | `^3.9.2` SDK | Cross-platform UI framework |
| **State Management** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) | `^9.1.1` | Predictable state management with Cubits |
| **Navigation & Routing** | [go_router](https://pub.dev/packages/go_router) | `^17.2.3` | Declarative URL-based routing |
| **Video Playback** | [awesome_video_player](https://pub.dev/packages/awesome_video_player) | `^1.0.5` | HLS/DASH/Live stream video player |
| **Audio Playback** | [just_audio](https://pub.dev/packages/just_audio) | `^0.10.6` | Feature-rich audio player for streams & files |
| **Background Audio** | [just_audio_background](https://pub.dev/packages/just_audio_background) | `^0.0.1-beta.17` | Lockscreen audio notification & background playback |
| **Audio Service** | [audio_service](https://pub.dev/packages/audio_service) | `^0.18.19` | Background media browser service bridge |
| **Local Database** | [hive_flutter](https://pub.dev/packages/hive_flutter) | `^1.1.0` | High-speed NoSQL database for bookmarks & cache |
| **Key-Value Storage** | [shared_preferences](https://pub.dev/packages/shared_preferences) | `^2.5.4` | Persistent storage for theme & locale settings |
| **Networking** | [http](https://pub.dev/packages/http) | `^1.6.0` | HTTP requests & background chunk streaming |
| **Image Caching** | [cached_network_image](https://pub.dev/packages/cached_network_image) | `^3.4.1` | Memory & disk caching for channel logos & art |
| **Screen Adaptation** | [flutter_screenutil](https://pub.dev/packages/flutter_screenutil) | `^5.9.3` | Responsive UI sizing across diverse screen densities |
| **XML Parsing** | [xml](https://pub.dev/packages/xml) | `^6.5.0` | XML parser for Electronic Program Guide (EPG) data |
| **Web Browser View** | [s_webview](https://pub.dev/packages/s_webview) | `^2.1.0` | WebView renderer for embedded video streams |
| **Connectivity** | [flutter_offline](https://pub.dev/packages/flutter_offline) | `^6.0.0` | Reactive network connectivity monitoring |
| **Animations & UI** | [lottie](https://pub.dev/packages/lottie), [shimmer](https://pub.dev/packages/shimmer), [card_swiper](https://pub.dev/packages/card_swiper) | Latest | Smooth visual effects, loaders & carousels |
| **Toasts & Feedback** | [toastification](https://pub.dev/packages/toastification) | `^3.0.3` | Customized toast notifications |
| **Sharing** | [share_plus](https://pub.dev/packages/share_plus) | `^10.1.4` | Native platform sharing dialogs |

---

## 🌐 APIs & Data Sources

Glitch TV aggregates media from open, legal, and public data providers:

| Data Type | Provider / Endpoint | Description |
| :--- | :--- | :--- |
| **Live TV Channels** | [IPTV-Org API](https://github.com/iptv-org/api) | Public IPTV channel database, streams, and logos |
| **Electronic Program Guide** | [Open-EPG](https://www.open-epg.com) | XML-based TV broadcast schedule feeds |
| **Radio Stations** | [Radio Browser API](https://www.radio-browser.info) | Community-driven global radio station directory |
| **Podcasts & Episodes** | [Apple iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI) | Podcast directory, RSS feed resolution, and episode metadata |

---

## 🏁 Getting Started

### Prerequisites
Before running the project, ensure you have:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.24.0` or higher recommended, SDK environment `^3.9.2`)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) (with Android SDK API 34+ / Gradle installed) or [Xcode](https://developer.apple.com/xcode/) (for iOS development)
- A connected physical device or emulator/simulator

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Ahmed-Moataz-glitch/Glitch-TV.git
   cd Glitch-TV
   ```

2. **Checkout the development branch:**
   ```bash
   git checkout development
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Generate localization files (if needed):**
   ```bash
   flutter gen-l10n
   ```

### Running the App

- **Run in debug mode on default connected device:**
  ```bash
  flutter run
  ```

- **Run with specific flavor/device:**
  ```bash
  flutter run -d chrome     # Web
  flutter run -d android    # Android
  flutter run -d ios        # iOS
  ```

---

## ⚙️ Platform Specific Configuration

### Android

The application requires specific permissions configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Network & Streaming -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

<!-- Background Playback -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>

<!-- Offline Podcast Storage & Media Scanning -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

- **Cleartext Traffic**: Enabled via `android:usesCleartextTraffic="true"` and custom network security config to support legacy HTTP radio/TV streams.
- **Hardware Acceleration**: Enabled with `android:hardwareAccelerated="true"` and `android:largeHeap="true"` for smooth video playback.

### iOS

For background audio streaming on iOS, ensure `UIBackgroundModes` is present in `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 📦 Building for Production

### Android APK / App Bundle

```bash
# Build split per-ABI release APKs
flutter build apk --release --split-per-abi

# Build Google Play Android App Bundle (AAB)
flutter build appbundle --release
```

### iOS IPA

```bash
# Build iOS Release Bundle
flutter build ipa --release
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Ahmed Moataz**

- GitHub: [@Ahmed-Moataz-glitch](https://github.com/Ahmed-Moataz-glitch)
- Project Repository: [Glitch-TV](https://github.com/Ahmed-Moataz-glitch/Glitch-TV)

<div align="center">
  <sub>Built with ❤️ and Flutter. Enjoy streaming! 📺📻🎙️</sub>
</div>
