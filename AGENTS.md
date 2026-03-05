# Content of repository

This repository contains a macOS app based on Swift and SwiftUI to synchronize folders with photos with the user's photo library. The user's photo library is the standard library of photos that the user sees in the Apple Photos app. As another use-case it supports the synchronization of photos from Lightroom Cloud to a local folder.

# Local folder to Photo Library

## Workflow

The user selects a folder on the local disk. The app scans the folder recursively. For every folder with subfolders the app creates a folder in the user's photo library. For every folder with photo files (instead of photos) the app creates an album including the photos.

The user should also be able to select a target folder in their photo library. If they select such a folder then all paths in the photo library should be relative to that folder. Otherwise the root of the photo library is used.

## Update

In general this should be an update process. That means, before the app creates a folder, an album or uploads a photo it first checks whether that element isn't already existing. If it already exists the app skips that element.

# Adobe Lightroom CC to local folder

## Workflow

In this use-case the user selects a folder from Adobe Lightroom CC (the cloud variant) as the source. And they select a local folder as the target. Then the app exports the photos of the folder (including subfolders) as JPG files to the local filesystem folder.

## Implementation Aspects

To access the photos, folders etc. from Lightroom CC use a corresponding Cloud API and not any local files or a locally installed Lightroom. In the future, this app will be ported to iOS/iPadOS as well and accessing the data from Lightroom should be reusable.

# Swift Coding Style

Whenever a method or a property of the current class, struct, enum etc. is used, then `self.` shoulf preceed the method/property to indicate that it is a member.

# Repo Structure

* All code related to the workflow "Local folder to Photo Library" must be implemented in the source code folder "Folder2Library".
* All code related to the workflow "Adobe Lightroom CC to local folder" must be implemented in the source code folder "Lightroom2Folder".
