//
//  Flickr Types.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 25/06/2022.
//

import Foundation

struct FlickrResponse: Codable, Equatable {
    let photos: Photos
    let stat: String
}

struct Photos: Codable, Equatable {

    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    let photo: [Photo]

    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photo
    }
}

struct Photo: Codable, Equatable {

    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int

    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
    }
}

