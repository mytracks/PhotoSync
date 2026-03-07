//
//  FilesystemTargetProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 07.03.26.
//

import Foundation

class FilesystemTargetConfiguration: TargetConfiguration {
    let rootDirectory: URL
    
    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }
}

@MainActor
@Observable
class FilesystemTargetProvider : TargetProvider {
    typealias Configuration = FilesystemTargetConfiguration
    
    func save(data: Data, fileName: String, configuration: Configuration) async throws {
        let filepath = configuration.rootDirectory.appendingPathComponent(fileName)
        
        FileManager.default.createFile(atPath: filepath.path, contents: data)
    }
}
