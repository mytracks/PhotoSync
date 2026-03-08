//
//  SyncEngine.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 06.03.26.
//

import Foundation

@MainActor
@Observable
class SyncEngine {
    enum Phase {
        case dryRun
        case requestRendering
        case load
    }
    
    var logEntries: [SyncLogEntry] = []
    var status: SyncStatus = .idle
    var dryRun: Bool = false
    var loadPhotoListDuringDryRun: Bool = false
    
    func sync<S: SourceProvider, T: TargetProvider>(
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetProvider: T,
        targetConfiguration: T.Configuration) {
            Task {
                do {
                    self.appendLog("Starting sync", type: .info)
                    let rootFolder = try await sourceProvider.getRootFolder(for: sourceConfiguration)
                    let rootAlbum = try await sourceProvider.getRootAlbum(for: sourceConfiguration)
                    
                    if let rootFolder {
                        self.appendLog("Root folder specified", type: .debug)
                        try await self.sync(
                            folder: rootFolder,
                            sourceProvider: sourceProvider,
                            sourceConfiguration: sourceConfiguration,
                            targetProvider: targetProvider,
                            targetConfiguration: targetConfiguration)
                    }
                    else if let rootAlbum {
                        self.appendLog("Root album specified", type: .debug)
                        try await self.sync(
                            album: rootAlbum,
                            sourceProvider: sourceProvider,
                            sourceConfiguration: sourceConfiguration,
                            targetProvider: targetProvider,
                            targetConfiguration: targetConfiguration)
                    }
                    else {
                        self.appendLog("Neither folder nor album specified", type: .error)
                    }
                    
                    self.appendLog("Sync finished", type: .info)
                }
                catch let exception {
                    self.appendLog("Unhandled error: \(exception)", type: .error)
                }
            }
        }
    
    private func formatCaptureDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        formatter.timeZone = .current
        // Note: mm is minutes; MM is month. hh is 12-hour; HH is 24-hour.
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter.string(from: date)
    }

    private func sync<S: SourceProvider, T: TargetProvider>(
        folder: any SourceFolder,
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetProvider: T,
        targetConfiguration: T.Configuration) async throws {
            self.appendLog("Processing albums of folder: \(folder.name)", type: .info)
            
            let albums = try await sourceProvider.getAlbums(folder: folder, configuration: sourceConfiguration)
            
            for album in albums {
                try await self.sync(
                    album: album,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
            
            self.appendLog("Processing subfolders of folder: \(folder.name)", type: .info)
            
            let subfolders = try await sourceProvider.getSubfolders(folder: folder, configuration: sourceConfiguration)

            for subfolder in subfolders {
                try await self.sync(
                    folder: subfolder,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
        }
    
    private func sync<S: SourceProvider, T: TargetProvider>(
        album: any SourceAlbum,
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetProvider: T,
        targetConfiguration: T.Configuration) async throws {
            if !self.dryRun || self.loadPhotoListDuringDryRun {
                try await self.syncPhotos(
                    album: album,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
    }
    
    private func syncPhotos<S: SourceProvider, T: TargetProvider>(
        album: any SourceAlbum,
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetProvider: T,
        targetConfiguration: T.Configuration) async throws {
            self.appendLog("Getting list of photos", type: .debug)
            let photos = try await sourceProvider.getPhotos(album: album, configuration: sourceConfiguration)
            let photoCount = photos.count
            self.appendLog("\(photoCount) photos found", type: .debug)

            var phase: Phase? = self.dryRun ? .dryRun : .requestRendering
            while phase != nil {
                var counter: Int = 0
                for photo in photos {
                    counter += 1
                    
                    let fileName = try await sourceProvider.getFilename(photo: photo, configuration: sourceConfiguration)
                    let captureDate = try await sourceProvider.getCaptureDate(photo: photo, configuration: sourceConfiguration)
                    
                    if let targetFileName = self.getExportFilename(fileName: fileName, captureDate: captureDate) {
                        if phase == .dryRun {
                            self.appendLog("Dry-run for for '\(targetFileName)' (\(counter)/\(photoCount))", type: .info)
                        }
                        else if try await !targetProvider.fileExists(fileName: targetFileName, configuration: targetConfiguration) {
                            if phase == .requestRendering {
                                // Request renderings
                                self.appendLog("Requesting JPEG rendering for '\(targetFileName)' (\(counter)/\(photoCount))", type: .info)
                                try await sourceProvider.requestJpegData(photo: photo, configuration: sourceConfiguration, jpgQuality: 1.0)
                            }
                            else if phase == .load {
                                // Load JPG data
                                if let jpegData = try await sourceProvider.getJpegData(photo: photo, configuration: sourceConfiguration, jpgQuality: 1.0) {
                                    self.appendLog("Loading JPEG data for '\(targetFileName)' (\(counter)/\(photoCount))", type: .info)
                                    try await targetProvider.save(
                                        data: jpegData,
                                        fileName: targetFileName,
                                        configuration: targetConfiguration)
                                }
                                else {
                                    self.appendLog("Unable to retrieve JPEG data for photo '\(targetFileName)'", type: .error)
                                }
                            }
                        }
                        else {
                            if phase == .load {
                                self.appendLog("File '\(targetFileName)' already exists (\(counter)/\(photoCount))", type: .info)
                            }
                        }
                    }
                    else {
                        if phase == .load {
                            self.appendLog("Unable to determine export filename for photo", type: .error)
                        }
                    }
                }

                if phase == .requestRendering {
                    phase = .load
                }
                else {
                    phase = nil
                }
            }
        }
    
    private func syncSubfolders<S: SourceProvider, T: TargetProvider>(
        folder: any SourceFolder,
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetProvider: T,
        targetConfiguration: T.Configuration) async throws {
            let subfolders = try await sourceProvider.getSubfolders(folder: folder, configuration: sourceConfiguration)
            
            for subfolder in subfolders {
                try await self.sync(
                    folder: subfolder,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
        }
    
    private func getExportFilename(fileName: String?, captureDate: Date?) -> String? {
        if let captureDateString = self.formatCaptureDate(captureDate) {
            return "\(captureDateString).jpg"
        }
        
        if let fileName {
            let baseName = (fileName as NSString).deletingPathExtension
            return "\(baseName).jpg"
        }
        
        return nil
    }
    
    func appendLog(_ message: String, type: SyncLogEntry.LogType) {
        self.logEntries.append(SyncLogEntry(message: message, type: type))
    }
}

