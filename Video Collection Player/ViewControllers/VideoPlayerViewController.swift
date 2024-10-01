//
//  VideoPlayerViewController.swift
//  Video Collection Player
//
//  Created by Dikan Chen on 9/30/24.
//

import UIKit
import AVKit

class VideoPlayerViewController: UIViewController {
    
    @IBOutlet weak var videoPlayerTableView: UITableView!
    
    var videoURLs: [URL] = []
    var videoDescriptions: [String] = []
    var selectedIndex: Int = 0
    var currentlyPlayingCell: VideoPlayerTableViewCell?
    
    var queuePlayer: AVQueuePlayer = AVQueuePlayer()
    var preloadedVideos: [AVPlayerItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        videoPlayerTableView.register(UINib(nibName: "VideoPlayerTableViewCell", bundle: nil), forCellReuseIdentifier: "VideoPlayerTableViewCell")
        videoPlayerTableView.delegate = self
        videoPlayerTableView.dataSource = self
        
        videoPlayerTableView.isPagingEnabled = true
        
        extendEdges()
        
        DispatchQueue.main.async {
            self.scrollToSelectedVideo()
        }
    }
    
    func extendEdges() {
        videoPlayerTableView.contentInsetAdjustmentBehavior = .never
    }
    
    func preloadNextVideos(from index: Int) {
        let remainingVideos = videoURLs.count - index - 1
        let videosToPreload = min(3, remainingVideos)
        
        preloadedVideos.removeAll()

        if videosToPreload > 0 {
            for i in 1...videosToPreload {
                let nextIndex = index + i
                
                // Ensure nextIndex is within bounds before accessing
                guard nextIndex < videoURLs.count else {
                    print("No more videos to preload.")
                    break
                }
                
                let nextVideoURL = videoURLs[nextIndex]
                let playerItem = AVPlayerItem(url: nextVideoURL)
                preloadedVideos.append(playerItem)
                print("video preloaded: \(nextVideoURL.absoluteString)")
            }
            
            queuePlayer.removeAllItems()
            for playerItem in preloadedVideos {
                queuePlayer.insert(playerItem, after: nil)
            }
        } else {
            print("No videos available to preload.")
        }
    }
    
    func scrollToSelectedVideo() {
        let indexPath = IndexPath(row: selectedIndex, section: 0)
        videoPlayerTableView.scrollToRow(at: indexPath, at: .top, animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playVideoInVisibleCell()
            self.preloadNextVideos(from: self.selectedIndex) // Preload the next 3 videos after scrolling
        }
    }
    
    func playVideoInVisibleCell() {
        let visibleCells = videoPlayerTableView.visibleCells
        if let visibleCell = visibleCells.first as? VideoPlayerTableViewCell {
            if let currentCell = currentlyPlayingCell, currentCell != visibleCell {
                currentCell.stopVideo()
            }
            
            visibleCell.playVideo()
            
            currentlyPlayingCell = visibleCell
        }
    }

    @IBAction func backBtnTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension VideoPlayerViewController: UITableViewDelegate, UITableViewDataSource, videoPlayerTableViewCellDelegate {
    func playButtonTapped(_ cell: VideoPlayerTableViewCell) {
        if let indexPath = videoPlayerTableView.indexPath(for: cell) {
            print("Play button tapped on row \(indexPath.row)")
        }
    }
    
    func sliderValueChanged(_ cell: VideoPlayerTableViewCell, value: Float) {
        if let indexPath = videoPlayerTableView.indexPath(for: cell) {
            print("Slider changed on row \(indexPath.row) with value \(value)")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoURLs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoPlayerTableViewCell", for: indexPath) as! VideoPlayerTableViewCell
        
        let videoURL = videoURLs[indexPath.row]
        cell.configure(with: videoURL)
        
        cell.descriptionLabel.text = videoDescriptions[indexPath.row]
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return videoPlayerTableView.bounds.height
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playVideoInVisibleCell()
        
        if let indexPath = videoPlayerTableView.indexPathsForVisibleRows?.first {
            // Preload the next 3 videos
            preloadNextVideos(from: indexPath.row)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currentlyPlayingCell?.stopVideo()
    }
}
