# Architecture of PhotoSync

PhotoSync is a SwiftUI-based application (macOS and iOS) designed to synchronize photos between different platforms, such as local filesystems, Apple Photos, and Adobe Lightroom.

## Core SyncEngine
The central component of the app is the `SyncEngine` (`PhotoSync/SyncEngine/SyncEngine.swift`). It operates on two main protocols:
- `SourceProvider`: Represents the source of photos, albums, and folders.
- `TargetProvider`: Represents the destination where photos should be synced.

The engine coordinates reading from the source and writing to the target, avoiding duplicates, handling dates, and logging the process (`SyncLogEntry`).

## Provider Implementations
- **Lightroom Source**: Implemented in `PhotoSync/Lightroom/`. Connects to Adobe Lightroom CC via Cloud API. It provides a `LightroomSourceProvider`. Authentication is handled via `AdobeAuthManager` and `OAuthKit`.
- **Filesystem Target**: Implemented in `PhotoSync/Filesystem/`. Writes photos to the local disk. It provides a `FilesystemTargetProvider`.

*Note*: The "Local Folder to Apple Photos Library" feature is currently implemented using a legacy standalone engine (`FolderToLibrarySyncEngine`) in `PhotoSync/Folder2Library/`. It has not yet been migrated to the new generic `SyncEngine` architecture as a `FilesystemSourceProvider` and `ApplePhotosTargetProvider`.

## UI Layer
- Built with SwiftUI.
- `MainView` acts as the root, orchestrating the configuration and logs.
- Configurations are defined in `PhotoSync/Views/Configuration/` (e.g., `SourceConfigurationView`, `TargetConfigurationView`).
- Dependencies like the `SyncEngine` and providers are injected into the SwiftUI view hierarchy using `.environment()`.

## Cross-Platform
The app is built for macOS and iOS. Use conditional compilation blocks (e.g., `#if os(macOS)`) when dealing with platform-specific APIs or UI elements (like window management or sizing).
