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
    func sync<S: SourceProvider, T: TargetProvider>(
        sourceProvider: S,
        sourceConfiguration: S.Configuration,
        targetProvider: T,
        targetConfiguration: T.Configuration) {
        Task {
            do {
                let rootFolder = try await sourceProvider.getRootFolder(for: sourceConfiguration)
                try await self.sync(
                    folder: rootFolder,
                    sourceProvider: sourceProvider,
                    sourceConfiguration: sourceConfiguration,
                    targetProvider: targetProvider,
                    targetConfiguration: targetConfiguration)
            }
            catch let exception {
                print("Error: \(exception)")
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
        let photos = try await sourceProvider.getPhotos(folder: folder, configuration: sourceConfiguration)

        for photo in photos {
            try await sourceProvider.requestJpegData(photo: photo, configuration: sourceConfiguration, jpgQuality: 1.0)
        }
        
        for photo in photos {
            let fileName = try await sourceProvider.getFilename(photo: photo, configuration: sourceConfiguration)
            let captureDate = try await sourceProvider.getCaptureDate(photo: photo, configuration: sourceConfiguration)
            if let jpegData = try await sourceProvider.getJpegData(photo: photo, configuration: sourceConfiguration, jpgQuality: 1.0) {
                if let targetFileName = self.getExportFilename(fileName: fileName, captureDate: captureDate) {
                    try await targetProvider.save(
                        data: jpegData,
                        fileName: targetFileName,
                        configuration: targetConfiguration)
                }
            }
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
}

