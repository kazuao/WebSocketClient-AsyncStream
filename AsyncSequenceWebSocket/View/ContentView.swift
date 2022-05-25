//
//  ContentView.swift
//  AsyncSequenceWebSocket
//
//  Created by kazunori.aoki on 2022/05/25.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel: ViewModel = .init()
    
    let client = WebSocketClient(url: "ws://localhost")

    var body: some View {
        ForEach(viewModel.names, id: \.id) { name in
            Text(name.name)
                .padding()
                .onAppear {
                    client.openConnect()

                    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                        self.client.send(request: RequestEntity(id: 1, name: "\(Int.random(in: 1...1000))"))
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
