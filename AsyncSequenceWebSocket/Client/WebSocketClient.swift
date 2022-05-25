//
//  WebSocketClient.swift
//  AsyncSequenceWebSocket
//
//  Created by kazunori.aoki on 2022/05/25.
//

import Foundation

final class WebSocketClient: NSObject {

    let url: String

    init(url: String) {
        self.url = url

        super.init()
        setup()
    }

    private var webSocket: URLSessionWebSocketTask?
    private var stream: WebSocketStream?

    var continuation: AsyncThrowingStream<ResponseEntity, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await message in stream! {
                        switch message {
                        case .string(let json):
                            guard let data = json.data(using: .utf8) else {
                                throw WebSocketError.invalidFormat
                            }
                            continuation.yield(try JSONDecoder().decode(ResponseEntity.self, from: data))

                        case .data:
                            continuation.finish(throwing: WebSocketError.invalidFormat)

                        @unknown default:
                            continuation.finish(throwing: WebSocketError.invalidFormat)
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func openConnect() {
        webSocket?.resume()
    }

    func send<T: Codable>(request: T) {

        let entity = try! JSONEncoder().encode(request)

        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            self.webSocket?.send(.data(entity)) { error in
                if let error = error {
                    print("Send error: \(error.localizedDescription)")
                }
            }
        }
    }
}

private extension WebSocketClient {

    func setup() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())

        let request: URLRequest = {
            var request = URLRequest(url: URL(string: url)!)
            request.timeoutInterval = 5
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("no-cache", forHTTPHeaderField: "cache-control")
            return request
        }()

        webSocket = session.webSocketTask(with: request)
        stream = .init(socket: webSocket!)
    }

    // WebSocketClient単体で受信するなら
    //    func receive() {
    //        guard let webSocket = webSocket else { return }
    //
    //        Task {
    //            let result = try await webSocket.receive()
    //            switch result {
    //            case .data(let data):
    //                print("Got data: \(data)")
    //
    //            case .string(let string):
    //                print("Got string: \(string)")
    //
    //            @unknown default: break
    //            }
    //
    //            receive()
    //        }
    //    }
}

extension WebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("Did connect to socket")
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("Did close connection with reason")

        openConnect()
    }
}
