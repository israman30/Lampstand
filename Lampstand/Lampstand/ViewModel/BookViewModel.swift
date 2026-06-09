//
//  BookViewModel.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import SwiftUI
import Combine

protocol BookViewModelProtocol {
    func fetchVerses() async
}

extension BookViewModel: BookViewModelProtocol { }

@MainActor
final class BookViewModel: ObservableObject {
    @Published var verses: [Verse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func fetchVerses() async {
        isLoading = true
        errorMessage = nil
        do {
            verses = try await networkManager.fetchVerses()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            verses = []
        }
        isLoading = false
    }
}
