# Content of repository

This repository contains a macOS and iOS app based on Swift and SwiftUI to synchronize folders with photos with the user's photo library, as well as from Lightroom Cloud to a local folder. 

# Use Cases

## 1. Local folder to Photo Library
The user selects a folder on the local disk. The app scans the folder recursively. For every folder with subfolders, the app creates a folder in the user's Apple Photos library. For every folder with photo files, it creates an album including the photos.
* **Update process**: It skips elements that already exist.
* **Code Location**: Currently implemented in `PhotoSync/Folder2Library/` using `FolderToLibrarySyncEngine`.

## 2. Adobe Lightroom CC to local folder
The user selects a folder from Adobe Lightroom CC (the cloud variant) as the source, and a local folder as the target. The app exports the photos of the folder (including subfolders) as JPG files to the local filesystem.
* **API**: Uses the Lightroom Cloud API (via `OAuthKit` and `AdobeAuthManager`), not a locally installed Lightroom.
* **Code Location**: `PhotoSync/Lightroom/` provides `LightroomSourceProvider`. `PhotoSync/Filesystem/` provides `FilesystemTargetProvider`. They are connected via the generic `SyncEngine` in `PhotoSync/SyncEngine/`.

# Architecture Context

The app is moving towards a generic `SyncEngine` architecture (located in `PhotoSync/SyncEngine/`) using `SourceProvider` and `TargetProvider` protocols. 
- **Lightroom to Filesystem** is fully integrated into this new architecture.
- **Local Folder to Apple Photos** currently uses its own engine but conceptually fits as a future `FilesystemSourceProvider` to `ApplePhotosTargetProvider`.

Dependencies are injected into the SwiftUI environment in `PhotoSyncApp.swift`. See `ARCHITECTURE.md` for more details.

# Swift Coding Style

* Whenever a method or a property of the current class, struct, enum etc. is used, then `self.` should precede the method/property to indicate that it is a member.
* Use modern Swift concurrency (`async/await`, `Task`) over completion handlers where possible.
* Use `@Observable` for view models and observable state.
