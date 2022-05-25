//
//  ViewModel.swift
//  AsyncSequenceWebSocket
//
//  Created by kazunori.aoki on 2022/05/25.
//

import Foundation

final class ViewModel: ObservableObject {

    @Published var names: [ResponseEntity] = []

    let client: WebSocketClient = .init(url: "ws://hoge")

    init() {
        setup()
    }

    func setup() {
        client.openConnect()

        Task {
            do {
                for try await name in client.continuation {
                    names.append(name)
                }
            } catch {
                print("Error", error)
            }
        }
    }
}
