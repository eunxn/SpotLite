//
//  FirestoreService.swift
//  MusicApp
//
//  Created by 김정은 on 6/9/25.
//

import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    func fetchAlbums(completion: @escaping ([Album]) -> Void) {
        db.collection("albums").getDocuments { snapshot, error in
            if let error = error {
                print("Firestore 오류: \(error.localizedDescription)")
                completion([])
                return
            }

            let albums = snapshot?.documents.compactMap { doc -> Album? in
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let artist = data["artist"] as? String,
                      let imageUrl = data["imageUrl"] as? String else {
                    return nil
                }
                return Album(title: title, artist: artist, imageUrl: imageUrl)
            } ?? []

            completion(albums)
        }
    }
}
