//
//  APIImageLinks.swift
//  RandomImageFetcher
//
//  Created by McMoodie on 2022-07-25.
//

import Foundation

struct Results: Codable {
    var results: [Result]
}

struct Result: Identifiable, Codable {
    let id: String
    let description: String?
    let urls: URLs
}

struct URLs: Codable {
    var full: String
}
