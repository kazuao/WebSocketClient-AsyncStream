//
//  WebSocketStream.swift
//  AsyncSequenceWebSocket
//
//  Created by kazunori.aoki on 2022/05/25.
//

import Foundation

final class WebSocketStream: AsyncSequence {

    typealias Element = URLSessionWebSocketTask.Message
    typealias AsyncIterator = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>.Iterator

    private var stream: AsyncThrowingStream<Element, Error>?
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    private let socket: URLSessionWebSocketTask

    init(socket: URLSessionWebSocketTask) {
        self.socket = socket
        stream = AsyncThrowingStream { continuation in
            self.continuation = continuation
            self.continuation?.onTermination = { @Sendable [socket] _ in
                socket.cancel()
            }
        }
    }

    func makeAsyncIterator() -> AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>.Iterator {
        guard let stream = stream else { fatalError() }

        socket.resume()
        listenForMessages()
        return stream.makeAsyncIterator()
    }

    private func listenForMessages() {
        socket.receive { [unowned self] result in
            switch result {
            case .success(let message):
                continuation?.yield(message)
                listenForMessages()

            case .failure(let error):
                continuation?.finish(throwing: error)
            }
        }
    }
}
