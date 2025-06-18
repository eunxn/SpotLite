//
//  Track.swift
//  MusicApp
//
//  Created by 김정은 on 6/4/25.
//

import Foundation

struct Track: Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let imageUrl: String?
}
