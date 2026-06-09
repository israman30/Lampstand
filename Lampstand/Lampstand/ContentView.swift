//
//  ContentView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
// https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json

import SwiftUI
import Combine

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

class BookViewModel: ObservableObject {
    @Published var books: [Book] = []
    
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func fetchBooks() async {
        do {
            let books = try await networkManager.fetchData()
            self.books = books
        } catch {
            print("Something went wrong: \(error)")
        }
    }
}

struct ContentView: View {
    @StateObject var viewModel: BookViewModel
    init() {
        self._viewModel = StateObject(wrappedValue: BookViewModel(networkManager: NetworkManager()))
    }
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("\(viewModel.books.count)")
        }
        .task {
            await viewModel.fetchBooks()
        }
    }
}

#Preview {
    ContentView()
}
