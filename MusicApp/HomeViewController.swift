//
//  SearchViewController.swift
//  MusicApp
//
//  Created by 김정은 on 6/2/25.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var albumList: [Album] = []
    var searchResults: [Track] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        tableView.delegate = self
        tableView.dataSource = self

        collectionView.delegate = self
        collectionView.dataSource = self

        // 최근 좋아요 트랙의 아티스트로 검색
        let favorites = FavoriteManager.shared.getFavorites()
        if let lastLikedTrack = favorites.last {
            let artistKeyword = lastLikedTrack.artist

            SpotifyAPIService.shared.fetchAccessToken { success in
                if success {
                    SpotifyAPIService.shared.searchTracks(keyword: artistKeyword) { tracks in
                        print("🔍 검색 결과 수: \(tracks.count)")
                        self.searchResults = tracks
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    print("❌ Spotify 인증 실패")
                }
            }
        } else {
            print("🧐 좋아요한 트랙이 없습니다")
        }

        FirestoreService.shared.fetchAlbums { albums in
            print("✅ 불러온 앨범 수: \(albums.count)")
            self.albumList = albums
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFavoriteAdded(_:)),
            name: .didAddFavoriteTrack,
            object: nil
        )

    }
    
    @objc private func handleFavoriteAdded(_ notification: Notification) {
        guard let track = notification.object as? Track else { return }

        let artist = track.artist
        SpotifyAPIService.shared.searchTracks(keyword: artist) { tracks in
            print("🔄 좋아요 반영된 검색 결과 수: \(tracks.count)")
            self.searchResults = tracks
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc private func handleFavoriteRemoved(_ notification: Notification) {
        guard let track = notification.object as? Track else { return }

        if searchResults.first?.artist == track.artist {
            SpotifyAPIService.shared.searchTracks(keyword: "new jeans") { tracks in
                self.searchResults = tracks
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }


}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCell", for: indexPath) as? AlbumCollectionViewCell else {
            return UICollectionViewCell()
        }

        let album = albumList[indexPath.item]

        cell.albumTitleLabel.text = album.title
        cell.artistLabel.text = album.artist
        
        // 이미지 로드
        if let url = URL(string: album.imageUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.albumImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }

        return cell
    }

    // 셀 크기 조정
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 140, height: 260)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "TrackCell")
        cell.textLabel?.text = track.title
        cell.detailTextLabel?.text = track.artist
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel
        return cell
    }
}

