//
//  GetPhotoResponse.swift
//  VirtualTourist
//
//  Created by Riham Mastour on 22/12/1441 AH.
//  Copyright © 1441 Riham Mastour. All rights reserved.
//

import Foundation

// MARK: - GetPhotoResponse
struct GetPhotoResponse: Codable {
    let photos: Photos
    let stat: String
}

// MARK: - Photos
struct Photos: Codable {
    let page, pages, perpage: Int
    let total: String
    let photo: [PhotoParse]
}

// MARK: - Photo
struct PhotoParse: Codable {
    let id: String
    let url_m: String
}

