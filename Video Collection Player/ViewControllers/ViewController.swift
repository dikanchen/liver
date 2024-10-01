//
//  ViewController.swift
//  Video Collection Player
//
//  Created by Dikan Chen on 9/30/24.
//

import UIKit

struct Video: Codable {
    let id: Int
    let video: String
    let thum: String
    let description: String
}

struct VideoData: Codable {
    let videos: [Video]
}

class ViewController: UIViewController {
    
    @IBOutlet weak var videoColletionView: UICollectionView!
    
    var videos: [Video] = []
    var imageCache = NSCache<NSString, UIImage>()
    
    var isLoadingData: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        videoColletionView.register(UINib(nibName: "VideoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "VideoCollectionViewCell")
        videoColletionView.delegate = self
        videoColletionView.dataSource = self
        fetchVideoData()
    }
    
    func fetchVideoData(isLoadingMore: Bool = false) {
        guard let url = Bundle.main.url(forResource: "videos", withExtension: "json") else { return }
        
        isLoadingData = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let videoData = try JSONDecoder().decode(VideoData.self, from: data)
                    DispatchQueue.main.async {
                        if isLoadingMore {
                            let currentVideoIDs = Set(self.videos.map { $0.id })
                            
                            let newVideos = videoData.videos.filter { !currentVideoIDs.contains($0.id) }
                            self.videos.append(contentsOf: newVideos)
                        } else {
                            self.videos = videoData.videos
                        }
                        print("videos are \(self.videos)")
                        self.videoColletionView.reloadData()
                        self.isLoadingData = false
                    }
                } catch {
                    print("Error decoding video data: \(error.localizedDescription)")
                    self.isLoadingData = false
                }
            }
        }.resume()
    }
    
    func loadMoreData() {
        guard !isLoadingData else { return }
        fetchVideoData(isLoadingMore: true)
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as! VideoCollectionViewCell
        let video = videos[indexPath.item]
        
        let cacheKey = NSString(string: video.thum)
        
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            cell.videoImageView.image = cachedImage
        } else {
            cell.thumLoadingIndicator.isHidden = false
            cell.thumLoadingIndicator.startAnimating()
            if let url = URL(string: video.thum) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        // Cache the image
                        self.imageCache.setObject(image, forKey: cacheKey)
                        DispatchQueue.main.async {
                            cell.videoImageView.image = image
                            cell.thumLoadingIndicator.isHidden = true
                            cell.thumLoadingIndicator.stopAnimating()
                        }
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = VideoPlayerViewController(nibName: "VideoPlayerViewController", bundle: nil)
        let videoURLs = videos.map { URL(string: $0.video)! }
        let videoDescriptions = videos.map { $0.description }
        vc.videoURLs = videoURLs
        vc.videoDescriptions = videoDescriptions
        vc.selectedIndex = indexPath.item
        print("selected video url is \(videoURLs[indexPath.item]), selected video description is \(videoDescriptions[indexPath.item])")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 3 - 10
        return CGSize(width: width, height: width)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height * 2 && !isLoadingData {
            loadMoreData()  // Load more data when nearing the bottom
        }
    }
}

