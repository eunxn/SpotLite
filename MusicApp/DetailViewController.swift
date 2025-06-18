//
//  DetailViewController.swift
//  MusicApp
//
//  Created by 김정은 on 6/4/25.
//

import UIKit
import FirebaseFirestore
import AVFoundation
import SafariServices

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var track: Track?

    private let albumImageView = UIImageView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let favoriteButton = UIButton(type: .system)
    private let segmentedControl = UISegmentedControl(items: ["spot", "미리듣기"])
    private let lyricsTextView = UITextView()
    
    // 댓글
    private let commentTableView = UITableView()
    private let commentTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var comments: [Comment] = []
    
    private let db = Firestore.firestore()
    
    // 미리 듣기
    private var player: AVPlayer?
    private let playButton = UIButton(type: .system)
    private var isPlayingPreview = false

    private var isFavorite = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupNavigationBar()
        setupUI()
        configureData()
    }

    private func setupNavigationBar() {
        navigationItem.titleView = createTitleView()
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("검색", for: .normal)
        backButton.tintColor = .systemBlue
        backButton.sizeToFit()
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(favoriteTapped))
    }

    @objc private func favoriteTapped() {
        guard let track = track else { return }

        if isFavorite {
            FavoriteManager.shared.remove(track: track)
        } else {
            FavoriteManager.shared.add(track: track)
        }

        isFavorite.toggle()
        updateFavoriteButton()
    }

    private func updateFavoriteButton() {
        let imageName = isFavorite ? "heart.fill" : "heart"
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: imageName)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let track = track {
            isFavorite = FavoriteManager.shared.isFavorite(track: track)
            updateFavoriteButton()
        }
    }


    private func createTitleView() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center

        let title = UILabel()
        title.text = track?.title ?? ""
        title.font = .boldSystemFont(ofSize: 17)
        title.textColor = .white

        let artist = UILabel()
        artist.text = track?.artist ?? ""
        artist.font = .systemFont(ofSize: 14)
        artist.textColor = .lightGray

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(artist)

        return stack
    }

    private func setupUI() {
        albumImageView.contentMode = .scaleAspectFit
        albumImageView.translatesAutoresizingMaskIntoConstraints = false

        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        lyricsTextView.isEditable = false
        lyricsTextView.backgroundColor = .clear
        lyricsTextView.textColor = .white
        lyricsTextView.font = .systemFont(ofSize: 16)
        lyricsTextView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(albumImageView)
        view.addSubview(segmentedControl)
        view.addSubview(lyricsTextView)

        NSLayoutConstraint.activate([
            albumImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            albumImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            albumImageView.widthAnchor.constraint(equalToConstant: 300),
            albumImageView.heightAnchor.constraint(equalToConstant: 300),

            segmentedControl.topAnchor.constraint(equalTo: albumImageView.bottomAnchor, constant: 20),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            lyricsTextView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            lyricsTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lyricsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            lyricsTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
        
        commentTableView.translatesAutoresizingMaskIntoConstraints = false
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTableView.isHidden = true

        commentTextField.placeholder = "댓글을 입력하세요"
        commentTextField.borderStyle = .roundedRect
        commentTextField.translatesAutoresizingMaskIntoConstraints = false
        commentTextField.isHidden = true

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.isHidden = true

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let sendImage = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config)
        sendButton.setImage(sendImage, for: .normal)
        sendButton.tintColor = .label
        sendButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)


        view.addSubview(commentTableView)
        view.addSubview(commentTextField)
        view.addSubview(sendButton)

        NSLayoutConstraint.activate([
            commentTableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            commentTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            commentTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            commentTableView.bottomAnchor.constraint(equalTo: commentTextField.topAnchor, constant: -10),
            
            commentTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            commentTextField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            commentTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            commentTextField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = .label
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.contentVerticalAlignment = .fill
        playButton.contentHorizontalAlignment = .fill
        playButton.addTarget(self, action: #selector(openYouTube), for: .touchUpInside)

        view.addSubview(playButton)

        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            playButton.widthAnchor.constraint(equalToConstant: 100),
            playButton.heightAnchor.constraint(equalToConstant: 100)
        ])

    }

    private func configureData() {
        if let track = track {
            // 앨범 이미지 로딩 (URL 기반)
            if let imageUrl = track.imageUrl, let url = URL(string: imageUrl) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.albumImageView.image = image
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func loadComments() {
        guard let trackID = track?.id else { return }

        db.collection("comments").document(trackID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                self.comments = documents.compactMap { doc in
                    guard let text = doc["text"] as? String else { return nil }
                    let timestamp = doc["timestamp"] as? Timestamp
                    return Comment(text: text, date: timestamp?.dateValue())
                }

                self.commentTableView.reloadData()
            }
    }
    
    private func formatDate(_ date: Date?) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .full

        guard let date = date else {
            return "방금 전"
        }

        let now = Date()
        let result = formatter.localizedString(for: date, relativeTo: now)

        // "0초 후"가 결과로 나올 경우 무조건 "방금 전"
        if result == "0초 후" {
            return "방금 전"
        }

        return result
    }
    
    func openYouTubeWebView(for track: Track) {
        let keyword = "\(track.title) \(track.artist)"
        let query = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.youtube.com/results?search_query=\(query)"

        if let url = URL(string: urlString) {
            let webVC = SFSafariViewController(url: url)
            present(webVC, animated: true)
        }
    }
    
    @objc private func openYouTube() {
        guard let track = track else { return }
        openYouTubeWebView(for: track)
    }

    
    @objc private func sendComment() {
        guard let trackID = track?.id else { return }
        guard let text = commentTextField.text, !text.isEmpty else { return }

        let newComment: [String: Any] = [
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("comments").document(trackID).collection("messages").addDocument(data: newComment) { error in
            if let error = error {
                print("댓글 저장 오류: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.commentTextField.text = ""
                    
                    // 테이블뷰 아래로 스크롤
                    if !self.comments.isEmpty {
                        let lastIndex = IndexPath(row: self.comments.count - 1, section: 0)
                        self.commentTableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
                    }
                    
                }
            }
        }
    }


    
    @objc private func segmentChanged() {
        let selected = segmentedControl.selectedSegmentIndex
        let isCommentMode = selected == 0  // "spot"일 때

        lyricsTextView.isHidden = isCommentMode
        commentTableView.isHidden = !isCommentMode
        commentTextField.isHidden = !isCommentMode
        sendButton.isHidden = !isCommentMode
        playButton.isHidden = isCommentMode

        if isCommentMode {
            loadComments()
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = comments[indexPath.row]

        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = comment.text
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.text = formatDate(comment.date)
        cell.detailTextLabel?.textColor = .lightGray
        cell.backgroundColor = .clear
        return cell
    }


}
