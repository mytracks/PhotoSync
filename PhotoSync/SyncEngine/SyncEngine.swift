//
//  SyncEngine.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 06.03.26.
//

import Foundation

struct SyncOptions {
    let createRootSourceFolderAsTargetFolder: Bool
}

@MainActor
@Observable
class SyncEngine {
    enum Phase {
        case dryRun
        case evaluateFilenames
        case requestRendering
        case load
    }
    
    var logEntries: [SyncLogEntry] = []
    var status: SyncStatus = .idle
    var dryRun: Bool = true
    var loadPhotoListDuringDryRun: Bool = true
    
    func sync<S: SourceProvider, T: TargetProvider>(
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetProvider: T,
        targetConfiguration: T.Configuration,
        syncOptions: SyncOptions
    ) {
        Task {
            do {
                self.appendLog("Starting sync", type: .info)
                let rootSourceFolder = try await sourceProvider.getRootFolder(for: sourceConfiguration)
                let rootSourceAlbum = try await sourceProvider.getRootAlbum(for: sourceConfiguration)
                let rootTargetFolder = try await targetProvider.getRootFolder(for: targetConfiguration)
                let rootTargetAlbum = try await targetProvider.getRootAlbum(for: targetConfiguration)
                
                if let rootSourceFolder, let rootTargetFolder {
                    self.appendLog("Root folder specified", type: .debug)
                    
                    var targetFolder = rootTargetFolder
                    if syncOptions.createRootSourceFolderAsTargetFolder {
                        targetFolder = try await targetProvider.getOrCreateFolder(
                            name: rootSourceFolder.name,
                            baseFolder: rootTargetFolder,
                            configuration: targetConfiguration)
                    }
                    
                    try await self.sync(
                        sourceFolder: rootSourceFolder,
                        sourceProvider: sourceProvider,
                        sourceConfiguration: sourceConfiguration,
                        targetFolder: targetFolder,
                        targetProvider: targetProvider,
                        targetConfiguration: targetConfiguration)
                }
                else if let rootSourceAlbum, let rootTargetAlbum {
                    self.appendLog("Root album specified", type: .debug)
                    try await self.sync(
                        sourceAlbum: rootSourceAlbum,
                        sourceProvider: sourceProvider,
                        sourceConfiguration: sourceConfiguration,
                        targetAlbum: rootTargetAlbum,
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
        sourceFolder: S.Folder,
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetFolder: T.Folder,
        targetProvider: T,
        targetConfiguration: T.Configuration) async throws {
            self.appendLog("Processing albums of folder: \(sourceFolder.name)", type: .info)
            
            let albums = try await sourceProvider.getAlbums(folder: sourceFolder, configuration: sourceConfiguration)
            
            for album in albums {
                let targetAlbum = try await targetProvider.getOrCreateAlbum(
                    name: album.name,
                    baseFolder: targetFolder,
                    configuration: targetConfiguration)
                
                try await self.sync(
                    sourceAlbum: album,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetAlbum: targetAlbum,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
            
            self.appendLog("Processing subfolders of folder: \(sourceFolder.name)", type: .info)
            
            let subfolders = try await sourceProvider.getSubfolders(folder: sourceFolder, configuration: sourceConfiguration)
            
            for subfolder in subfolders {
                let targetFolder = try await targetProvider.getOrCreateFolder(
                    name: subfolder.name,
                    baseFolder: targetFolder,
                    configuration: targetConfiguration)
                
                try await self.sync(
                    sourceFolder: subfolder,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetFolder: targetFolder,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
        }
    
    private func sync<S: SourceProvider, T: TargetProvider>(
        sourceAlbum: S.Album,
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetAlbum: T.Album,
        targetProvider: T,
        targetConfiguration: T.Configuration) async throws {
            if !self.dryRun || self.loadPhotoListDuringDryRun {
                try await self.syncPhotos(
                    sourceAlbum: sourceAlbum,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetAlbum: targetAlbum,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
        }
    
    private func syncPhotos<S: SourceProvider, T: TargetProvider>(
        sourceAlbum: S.Album,
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetAlbum: T.Album,
        targetProvider: T,
        targetConfiguration: T.Configuration) async throws {
            self.appendLog("Getting list of photos", type: .debug)
            let photos = try await sourceProvider.getPhotos(album: sourceAlbum, configuration: sourceConfiguration)
            let photoCount = photos.count
            self.appendLog("\(photoCount) photos found", type: .debug)
            
            var targetFilenameMap = [S.Photo : String]()
            var targetFilenames = Set<String>()
            
            var phase: Phase? = .evaluateFilenames
            while phase != nil {
                var counter: Int = 0
                for photo in photos {
                    counter += 1
                    
                    let fileName = try await sourceProvider.getFilename(photo: photo, configuration: sourceConfiguration)
                    let captureDate = try await sourceProvider.getCaptureDate(photo: photo, configuration: sourceConfiguration)
                    
                    if phase == .evaluateFilenames {
                        if let targetFileName = self.getExportFilename(fileName: fileName, captureDate: captureDate, existingFilenames: targetFilenames) {
                            targetFilenameMap[photo] = targetFileName
                            targetFilenames.insert(targetFileName)
                        }
                    }
                    else {
                        if let targetFileName = targetFilenameMap[photo] {
                            if phase == .dryRun {
                                self.appendLog("Dry-run for for '\(targetFileName)' (\(counter)/\(photoCount))", type: .info)
                            }
                            else if try await !targetProvider.fileExists(fileName: targetFileName, album: targetAlbum, configuration: targetConfiguration) {
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
                                            album: targetAlbum,
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
                }
                
                if phase == .evaluateFilenames {
                    if self.dryRun {
                        phase = .dryRun
                    }
                    else {
                        phase = .requestRendering
                    }
                }
                else if phase == .requestRendering {
                    phase = .load
                }
                else {
                    phase = nil
                }
            }
        }
    
    private func getExportFilename(fileName: String?, captureDate: Date?, existingFilenames: Set<String>) -> String? {
        var count = 0
        
        while true {
            var filenameProposal: String?
            
            let postfix = count > 0 ? "-\(String(format: "%04d", count))" : ""
            
            if let captureDateString = self.formatCaptureDate(captureDate) {
                filenameProposal = "\(captureDateString)\(postfix).jpg"
            }
            else if let fileName {
                let baseName = (fileName as NSString).deletingPathExtension
                filenameProposal = "\(baseName)\(postfix).jpg"
            }
            
            guard let filenameProposal else {
                return nil
            }
            
            if !existingFilenames.contains(filenameProposal) {
                return filenameProposal
            }
            
            count += 1
        }
    }
    
    func appendLog(_ message: String, type: SyncLogEntry.LogType) {
        self.logEntries.append(SyncLogEntry(message: message, type: type))
    }
}

