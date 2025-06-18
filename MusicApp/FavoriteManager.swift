//
//  FavoriteManager.swift
//  MusicApp
//
//  Created by 김정은 on 6/16/25.
//

import Foundation

class FavoriteManager {
    static let shared = FavoriteManager()
    private init() {
        loadFavorites()
    }
    
    private let key = "FavoriteTracks"
    private(set) var favorites: [Track] = []

    func add(track: Track) {
        if !isFavorite(track: track) {
            favorites.append(track)
            saveFavorites()
            
            NotificationCenter.default.post(
                name: .didAddFavoriteTrack,
                object: track
            )
        }
    }
    
    func remove(track: Track) {
        favorites.removeAll { $0.title == track.title && $0.artist == track.artist }
        saveFavorites()
    }



    func isFavorite(track: Track) -> Bool {
        return favorites.contains { $0.title == track.title && $0.artist == track.artist }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: key),
           let savedTracks = try? JSONDecoder().decode([Track].self, from: data) {
            favorites = savedTracks
        }
    }

    func getFavorites() -> [Track] {
        return favorites
    }

}

extension Notification.Name {
    static let didAddFavoriteTrack = Notification.Name("didAddFavoriteTrack")
}
