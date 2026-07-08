# PhotoSync AI Context & Instructions

This document provides context and guidelines for AI agents working in this repository. Please read this file to understand the architecture, purpose, and technologies used before starting any tasks.

## Project Overview

**PhotoSync** is a native application for **macOS** and **iOS** designed to synchronize photos from various sources to different targets. Currently, it supports:
- **Source:** Adobe Lightroom
- **Target:** Local Filesystem (using Security-Scoped URLs for sandboxed access)

The app connects to the source, traverses its structure (Folders -> Albums -> Photos), and replicates that exact hierarchy in the target location, downloading and saving the images (e.g., JPEGs) that are missing or outdated.

## Technology Stack

- **Language:** Swift (Requires Swift 5.9+, uses modern features like macros and concurrency)
- **UI Framework:** SwiftUI (used exclusively for both macOS and iOS, sharing most code using `#if os(macOS)` conditionals when necessary)
- **State Management:** Observation Framework (`@Observable`, `@Environment(MyClass.self)`)
- **Concurrency:** Swift Concurrency (`async/await`, `@MainActor`, `Task`)
- **Dependency Management:** Swift Package Manager (SPM) embedded in the Xcode project (`.xcodeproj`)
- **External Dependencies:** `OAuthKit` (github.com/codefiesta/OAuthKit) used for Adobe API OAuth 2.0 PKCE authentication.

## Architecture

The application is structured around a flexible Extract-Transform-Load (ETL) pattern, allowing future addition of new sources and targets.

### Core Protocols
- **`SourceProvider` / `TargetProvider`:** Abstract interfaces for reading from a source or writing to a target. Found in `PhotoSync/SyncEngine/SourceProvider.swift` and `TargetProvider.swift`. 
- **`SourceConfiguration` / `TargetConfiguration`:** Protocols storing settings specific to a provider type.
- **Model Interfaces:** `SourceFolder`, `SourceAlbum`, `SourcePhoto`, `TargetFolder`, `TargetAlbum`. 

### Key Components
1. **`SyncEngine`**: 
   - Found in `PhotoSync/SyncEngine/SyncEngine.swift`.
   - The heart of the app. It manages the actual sync process: discovering folders/albums, verifying if the target file exists or is outdated (by capture date / modification date), requesting JPEGs, and saving them.
   - Operates in phases (e.g., `dryRun`, `evaluateFilenames`, `requestRendering`, `load`).
2. **`AdobeAuthManager` & `LightroomConnector`**:
   - Manages API interactions with Adobe Lightroom, handling token lifecycles via `OAuthKit`.
3. **`FilesystemTargetProvider`**:
   - Implements `TargetProvider` using `FileManager` and `SecurityScopedResource` access for the local filesystem.
4. **SwiftUI Views**:
   - Located in `PhotoSync/Views`. `MainView` handles the primary layout. Configuration is split into `SourceConfiguration` and `TargetConfiguration` subfolders.

## Agent Guidelines & Conventions

When proposing changes, fixing bugs, or implementing new features, please adhere strictly to these conventions:

1. **Keep Platform Support Unbroken**: Always ensure changes compile and run on both iOS and macOS. Use `#if os(macOS)` and `#if os(iOS)` blocks when working with platform-specific APIs (like `UIApplication` vs `NSWorkspace`, or window management).
2. **Use Swift Concurrency**: Use `async`/`await` for all asynchronous operations (API calls, file I/O). Do not use completion handlers or Combine (`AnyPublisher`) unless interfacing with an older API that strictly requires it.
3. **Modern SwiftUI & Observation**: Use the `@Observable` macro instead of `ObservableObject` / `@Published`. Inject dependencies using `@Environment(MyClass.self)`.
4. **Extend Providers, Don't Tightly Couple**: When adding a new source (e.g., Google Photos, Apple Photos) or a new target (e.g., S3, Dropbox), implement the `SourceProvider`/`TargetProvider` protocols. Do *not* inject provider-specific logic into `SyncEngine`. 
5. **UI Structure**: Maintain the pattern of separating Configuration Views (`PhotoSync/Views/Configuration/`) for each provider type.
6. **No Tests (Yet)**: There is currently no `Tests` target. If creating tests, you must create the target in the Xcode project first, or ask the user to do so.
7. **Logging**: Feed all sync progress or error logs directly into the `SyncEngine`'s `appendLog(_:type:)` function instead of using generic `print()` statements, so they appear in the UI's `LogView`.

## Example Workflows

- **Adding a new Source**: 
  1. Create a folder (e.g., `PhotoSync/GooglePhotos/Connector`).
  2. Implement `SourceProvider`, `SourceFolder`, `SourceAlbum`, `SourcePhoto`.
  3. Create a config view inside `PhotoSync/Views/Configuration/SourceConfiguration/`.
  4. Instantiate the provider in `PhotoSyncApp.swift` and inject it into the environment if needed.
