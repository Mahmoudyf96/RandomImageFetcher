//
//  PhotoViewModel.swift
//  RandomImageFetcher
//
//  Created by McMoodie on 2022-07-24.
//

import SwiftUI
import Photos
import Combine

class PhotoViewModel: ObservableObject {
    // Photo Authorization
    @Published var authorized: Bool = false
    @Published var denied: Bool = false
    
    // Camera Roll Fetching
    @Published var photos: [UIImage] = []
    @Published var currentCameraPhoto: UIImage = UIImage()
    @Published var photoProgress: Double = 0.0
    @Published var photoBusy: Bool = false
    
    // API Fetching
    @Published var apiBusy: Bool = false
    
    // Random Number of Photos
    @Published var numOfPhotos: Int = 10
    @Published var randomSplit: Int = 0
    
    // Combine
    var cancellables = Set<AnyCancellable>()
    
    init() {
        // Making sure the user has allowed us to access their photos
        requestPhotoAccess()
    }
    
    func changeCurrentPhoto(currentWheelValue: Double) {
        if !photos.isEmpty {
            let wheelSections = 360 / numOfPhotos
            var position = 0
            for num in 0..<numOfPhotos {
                if (wheelSections*num...wheelSections*num+wheelSections).contains(Int(currentWheelValue)) {
                    position = num
                }
            }
            
            withAnimation {
                self.currentCameraPhoto = photos[position]
            }
        }
    }
    
    func requestPhotoAccess() {
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        if photoStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch (status) {
                    case .authorized:
                        self.authorized = true
                    case .limited:
                        self.authorized = true
                    case .denied:
                        self.denied = true
                    default:
                        self.authorized = false
                    }
                }
            }
        } else if photoStatus == .authorized || photoStatus == .limited {
            self.authorized = true
        } else {
            self.denied = true
        }
    }
    
    func fetchRandomPhotos() {
        self.photos = []
        self.numOfPhotos = Int.random(in: 10...20)
        self.photoBusy = true
        self.apiBusy = true
        
        self.randomSplit = Int.random(in: 1...numOfPhotos)
        let apiCount = numOfPhotos - randomSplit
        
        DispatchQueue.main.async {
            self.fetchAPILinks(count: apiCount)
            self.fetchPhotos(count: self.randomSplit)
        }
        
        print("Total Fetched Photos: \(self.numOfPhotos)")
        print("Fetched \(apiCount) from API")
        print("Fetched \(self.randomSplit) from camera roll")
    }
    
    func fetchPhotos(count: Int) {
        // Fetch Photo Setup
        let imgManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        if 10...20 ~= fetchResult.count || fetchResult.count > 20 {
            for _ in 0 ..< count {
                imgManager.requestImage(for: fetchResult.object(at: Int.random(in: 0...fetchResult.count)), targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                    if let image = image {
                        DispatchQueue.main.async {
                            self.photos.append(image)
                            self.photoProgress += 1.0
                            if self.photoProgress == Double(self.numOfPhotos) {
                                self.photoProgress = 0
                                self.photoBusy = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchAPILinks(count: Int) {
        fetchAPIPhotos(count: count)
            .sink(receiveCompletion: { print("Received Completion: \($0)."); self.apiBusy = false}, receiveValue: { photo in
                self.photoProgress += Double(photo.count)
                self.photos.append(contentsOf: photo)
            })
            .store(in: &cancellables)
    }
    
    private func downloadAndDecode(count: Int) -> AnyPublisher<[Result], Never> {
        let key = "VAbUGxDFWKzxF4d3Y1rImkHxjAhcaM7Q9no0TLqwCyM"
        guard let url = URL(string: "https://api.unsplash.com/photos/random?count=\(count)&client_id=\(key)") else {
            return Empty(completeImmediately: false)
                .eraseToAnyPublisher()
        }
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession(configuration: config)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("Accept-Version", forHTTPHeaderField: "v1")
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response -> Data in
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200 else { throw URLError(.badServerResponse) }
                
                return data
            }
            .decode(type: [Result].self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    private func fetchAPIPhotos(count: Int) -> AnyPublisher<[UIImage], Never> {
        return Just(())
            .flatMap { i -> AnyPublisher<[Result], Never> in
                return self.downloadAndDecode(count: count)
            }
            .flatMap { results -> AnyPublisher<[UIImage], Never> in
                let images = results.map { result -> AnyPublisher<UIImage, Never> in
                    let url = URL(string: result.urls.full)!
                    return URLSession.shared.dataTaskPublisher(for: url)
                        .map { UIImage(data: $0.data)! }
                        .replaceError(with: UIImage())
                        .eraseToAnyPublisher()
                }
                return Publishers.MergeMany(images)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func navToSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
