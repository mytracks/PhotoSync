//
//  TargetProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 07.03.26.
//

import Foundation

protocol TargetConfiguration {
}

protocol TargetProvider {
    associatedtype Configuration: TargetConfiguration

    func fileExists(fileName: String, configuration: Configuration) async throws -> Bool
    func save(data: Data, fileName: String, configuration: Configuration) async throws
}
