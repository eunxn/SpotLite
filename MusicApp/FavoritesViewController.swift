//
//  FavoritesViewController.swift
//  MusicApp
//
//  Created by 김정은 on 6/2/25.
//

import UIKit

class FavoritesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var musicImageView: UIImageView!
    
    var favoriteTracks: [Track] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        musicImageView.image = UIImage(systemName: "music.house.fill")
        musicImageView.tintColor = .systemGray3
        musicImageView.isHidden = !favoriteTracks.isEmpty

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        favoriteTracks = FavoriteManager.shared.getFavorites()
        musicImageView.isHidden = !favoriteTracks.isEmpty
        tableView.reloadData()
    }

}

extension FavoritesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteTracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as? TrackTableViewCell else {
            return UITableViewCell()
        }

        let track = favoriteTracks[indexPath.row]
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
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let track = self.favoriteTracks[indexPath.row]
            FavoriteManager.shared.remove(track: track)
            
            self.favoriteTracks.remove(at: indexPath.row)
            
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                if self.favoriteTracks.isEmpty {
                    // 👉 완전 초기화가 필요할 때
                    self.tableView.reloadData()
                }
                self.musicImageView.isHidden = !self.favoriteTracks.isEmpty
            })

            completionHandler(true)
        }

        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

}
