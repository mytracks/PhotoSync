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
    func sync<P: SourceProvider>(sourceProvider: P, sourceConfiguration: P.Configuration) {
        Task {
            do {
                let rootFolder = try await sourceProvider.getRootFolder(for: sourceConfiguration)
                try await self.sync(folder: rootFolder, sourceProvider: sourceProvider, sourceConfiguration: sourceConfiguration)
            }
            catch let exception {
                print("Error: \(exception)")
            }
        }
    }
    
    private func sync<P: SourceProvider>(folder: any SourceFolder, sourceProvider: P, sourceConfiguration: P.Configuration) async throws {
        let photos = try await sourceProvider.getPhotos(folder: folder, configuration: sourceConfiguration)

        for photo in photos {
            try await sourceProvider.requestJpegData(photo: photo, configuration: sourceConfiguration, jpgQuality: 1.0)
        }
        
        for photo in photos {
            let fileName = try await sourceProvider.getFilename(photo: photo, configuration: sourceConfiguration)
            let captureDate = try await sourceProvider.getCaptureDate(photo: photo, configuration: sourceConfiguration)
            let jpegData = try await sourceProvider.getJpegData(photo: photo, configuration: sourceConfiguration, jpgQuality: 1.0)
            print("Photo: \(fileName) \(captureDate) \(jpegData?.count)")
        }
    }
}
