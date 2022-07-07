//
//  Flickr Client.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 22/06/2022.
//

import Foundation


class FlickrClient {
    
    static let apiKey = "2d5e33493e01cd248f6d52fba308950a"
    static let secret = "90c750890a52ebac"

    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest/?method=flickr.photos.getRecent"
        static let photoBase = "https://live.staticflickr.com/"

        case photoRequest
        case photoURL(String,String,String)
        
        var stringValue: String {
            switch self {
            case .photoRequest:
                return Endpoints.base + "&api_key=\(FlickrClient.apiKey)&format=json&nojsoncallback=1"
            case .photoURL(let server,let id, let secret):
                return Endpoints.photoBase + "\(server)/\(id)_\(secret).jpg"
            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    //MARK: Networking Methods
    
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
                  let responseObject = try decoder.decode(responseType, from: data)
                  print("responseObject: \(responseObject)")
                  DispatchQueue.main.async {
                      completion(responseObject, nil)
                  }
              } catch {
                  do {
                      let errorResponse = try decoder.decode(FlickrResponse.self, from: data) as! Error
                      DispatchQueue.main.async {
                          completion(nil, errorResponse)
                      }
                  } catch {
                      DispatchQueue.main.async {
                          completion(nil, error)
                      }
                  }
              }
          }
          task.resume()
          
          return task
      }
    
    class func photoRequest(completion: @escaping (FlickrResponse?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.photoRequest.url, responseType: FlickrResponse.self) { response, error in
            print("requested URL: \(Endpoints.photoRequest.url)")
            if let response = response {
                DispatchQueue.main.async {
                    completion(response, nil)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func downloadingPhotos(server: String, id: String, secret: String, completion: @escaping (Data?, Error?) -> Void) {
        print(Endpoints.photoURL(server, id, secret).url)
        let task = URLSession.shared.dataTask(with: Endpoints.photoURL(server, id, secret).url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
}
