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

    func saveJpeg(data: Data, fileName: String) async throws
    
}
