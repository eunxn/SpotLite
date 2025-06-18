//
//  SpotifyAPIService.swift
//  MusicApp
//
//  Created by 김정은 on 6/4/25.
//

import Foundation

class SpotifyAPIService {
    static let shared = SpotifyAPIService()

    private var clientID: String = ""
    private var clientSecret: String = ""
    private var accessToken: String?

    private init() {
        loadAPIKeys()
    }
    
    private func loadAPIKeys() {
            if let url = Bundle.main.url(forResource: "SpotifyAPIKey", withExtension: "plist"),
               let data = try? Data(contentsOf: url),
               let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                clientID = dict["SPOTIFY_CLIENT_ID"] as? String ?? ""
                clientSecret = dict["SPOTIFY_CLIENT_SECRET"] as? String ?? ""
            } else {
                print("SpotifyAPIKey.plist 로딩 실패")
            }
        }


    func fetchAccessToken(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let authString = "\(clientID):\(clientSecret)"
        guard let authData = authString.data(using: .utf8)?.base64EncodedString() else {
            completion(false)
            return
        }

        request.addValue("Basic \(authData)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyString = "grant_type=client_credentials"
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            self.accessToken = token
            print("✅ Access Token: \(token)")
            DispatchQueue.main.async { completion(true) }
        }.resume()
    }

    func searchTracks(keyword: String, completion: @escaping ([Track]) -> Void) {
        guard let token = accessToken else {
            print("❗️Access Token이 없음")
            completion([])
            return
        }

        let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=20"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion([])
                return
            }

            let tracks = self.parseTracks(from: data)
            DispatchQueue.main.async {
                completion(tracks)
            }
        }.resume()
    }

    private func parseTracks(from data: Data) -> [Track] {
        var results: [Track] = []

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tracksDict = json["tracks"] as? [String: Any],
              let items = tracksDict["items"] as? [[String: Any]] else {
            return []
        }

        for item in items {
            let id = item["id"] as? String ?? UUID().uuidString  // fallback
            let title = item["name"] as? String ?? "Unknown Title"
            let artists = (item["artists"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
            let artist = artists.joined(separator: ", ")
            
            let album = item["album"] as? [String: Any]
            let images = album?["images"] as? [[String: Any]]
            let imageUrl = images?.first?["url"] as? String

            results.append(Track(id: id, title: title, artist: artist, imageUrl: imageUrl))
        }

        return results
    }

    
    func searchAlbums(keyword: String, completion: @escaping ([Album]) -> Void) {
        guard let token = accessToken else {
            print("Access Token 없음")
            completion([])
            return
        }

        let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=album&limit=20"
        guard let url = URL(string: urlString) else {
            print("URL 생성 실패")
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("에러: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let data = data else {
                print("데이터 없음")
                completion([])
                return
            }

            // JSON 파싱
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let albumsDict = json["albums"] as? [String: Any],
                      let items = albumsDict["items"] as? [[String: Any]] else {
                    print("JSON 구조 파싱 실패")
                    completion([])
                    return
                }

                let albums: [Album] = items.compactMap { item in
                    guard let title = item["name"] as? String,
                          let artists = item["artists"] as? [[String: Any]],
                          let images = item["images"] as? [[String: Any]],
                          let imageUrl = images.first?["url"] as? String else {
                        return nil
                    }

                    let artistNames = artists.compactMap { $0["name"] as? String }.joined(separator: ", ")
                    return Album(title: title, artist: artistNames, imageUrl: imageUrl)
                }

                DispatchQueue.main.async {
                    completion(albums)
                }

            } catch {
                print("JSON 파싱 에러: \(error)")
                completion([])
            }

        }.resume()
    }


}

