//
//  SearchViewController.swift
//  MusicApp
//
//  Created by 김정은 on 6/5/25.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var musicImageView: UIImageView!
    
    var searchResults: [Track] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 80

            view.backgroundColor = .systemBackground
            
            searchBar.delegate = self
            searchBar.placeholder = "아티스트, 노래를 검색해보세요!"
            tableView.delegate = self
            tableView.dataSource = self
            musicImageView.image = UIImage(systemName: "music.house.fill")
            musicImageView.tintColor = .systemGray3
            musicImageView.isHidden = false

            
            SpotifyAPIService.shared.fetchAccessToken { success in
                if success {
                    print("Spotify 인증 완료")
                } else {
                    print("Spotify 인증 실패")
                }
            }
        }
    }

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let keyword = searchBar.text, !keyword.isEmpty else { return }
        print("🔍 검색어: \(keyword)")
        searchBar.resignFirstResponder()
        
        SpotifyAPIService.shared.searchTracks(keyword: keyword) { tracks in
            self.searchResults = tracks
            self.musicImageView.isHidden = !tracks.isEmpty // 이미지뷰 표시 여부
            self.tableView.reloadData()
        }
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as? TrackTableViewCell else {
            return UITableViewCell()
    }

    let track = searchResults[indexPath.row]
    cell.titleLabel.text = track.title
    cell.artistLabel.text = track.artist

    if let imageUrl = track.imageUrl, let url = URL(string: imageUrl) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    cell.albumImageView.image = UIImage(data: data)
                }
            }
        }.resume()
    } else {
        cell.albumImageView.image = nil
    }

        return cell
    }

func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = searchResults[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController {
            detailVC.track = selectedTrack
            navigationController?.pushViewController(detailVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
