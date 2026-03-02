# Content of repository

This repository contains a macOS app based on Swift and SwiftUI to synchronize folders with photos with the user's photo library. The user's photo library is the standard library of photos that the user sees in the Apple Photos app.

# Workflow

The user selects a folder on the local disk. The app scans the folder recursively. For every folder with subfolders the app creates a folder in the user's photo library. For every folder with photo files (instead of photos) the app creates an album including the photos.

The user should also be able to select a target folder in their photo library. If they select such a folder then all paths in the photo library should be relative to that folder. Otherwise the root of the photo library is used.

# Update

In general this should be an update process. That means, before the app creates a folder, an album or uploads a photo it first checks whether that element isn't already existing. If it already exists the app skips that element.

# Swift Coding Style

Whenever a method or a property of the current class, struct, enum etc. is used, then `self.` shoulf preceed the method/property to indicate that it is a member.
