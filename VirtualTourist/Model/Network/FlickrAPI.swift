//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Riham Mastour on 22/12/1441 AH.
//  Copyright © 1441 Riham Mastour. All rights reserved.
//

import Foundation

class FlickrAPI {
   
    static let baseURL = "https://api.flickr.com/services/rest"
    static let apiKeyParam = "?api_key=c18a2d71bcfc39668d2cfbfe39850fb7"
    
    static func getPhotos(lat:Double, lon:Double, completionHandler: @escaping (_ data: [Any]?, _ errString:String?) -> Void){
        
        let url = URL(string: baseURL + apiKeyParam + "&method=flickr.photos.search" + "&lat=\(lat)" + "&lon=\(lon)" + "&format=json" + "&safe_search=1" + "&per_page=21" + "&accuracy=11" + "&nojsoncallback=1"+"&extras=url_m")!

        taskForGETRequest(url: url, responseType: GetPhotoResponse.self) { (response, error) in
            if let response = response {

                    print(response.photos.photo)
                    completionHandler(response.photos.photo,"")

            
            } else {
                debugPrint(error!)
                    DispatchQueue.main.async {
                completionHandler([], error?.localizedDescription)
                }
            }
        }
    }

     @discardableResult class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                completion(nil, error)
                }
            }
        }
        task.resume()
        
        return task
    }
}
