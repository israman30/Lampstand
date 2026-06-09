//
//  ContentView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
// https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json

import SwiftUI

struct BookList: Decodable {
    var data: [Book]
}

struct Book: Decodable {
    let book: String
    let chapters: Int
    let verse: Int
    let text: String
}

final class NetworkManager {
    func fetchData() async throws -> [Book] {
        let url = URL(string: "https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(BookList.self, from: data).data
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
