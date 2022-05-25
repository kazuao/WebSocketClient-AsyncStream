//
//  ResponseEntity.swift
//  AsyncSequenceWebSocket
//
//  Created by kazunori.aoki on 2022/05/25.
//

import Foundation

struct ResponseEntity: Codable, Identifiable {
    var id = UUID()
    let name: String
}
