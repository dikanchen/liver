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
    
    var preloadedItems: [URL: AVPlayerItem] = [:]
    
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
                preloadedItems[nextVideoURL] = playerItem
                print("video preloaded: \(nextVideoURL.absoluteString)")
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

            // Get the index of the visible cell
            if let indexPath = videoPlayerTableView.indexPath(for: visibleCell) {
                let videoURL = self.videoURLs[indexPath.row]
                DispatchQueue.main.async {
                    if let preloadedItem = self.preloadedItems[videoURL] {
                        // Use the preloaded AVPlayerItem to play the video
                        visibleCell.configure(with: preloadedItem)
                        visibleCell.playVideo()
                        print("Playing preloaded video at index \(indexPath.row)")
                    } else {
                        // Fallback to loading the video normally if not preloaded or not ready
                        visibleCell.configure(with: videoURL)
                        visibleCell.playVideo()
                        let playerItem = AVPlayerItem(url: videoURL)
                        self.preloadedItems[videoURL] = playerItem
                        print("Playing non-preloaded video at index \(indexPath.row)")
                    }
                    
                    // Preload the next 3 videos
                    self.preloadNextVideos(from: indexPath.row)
                }
            }

            currentlyPlayingCell = visibleCell
        }
    }

    @IBAction func backBtnTapped(_ sender: Any) {
        VideoPlayerTableViewCell.player.pause()
        VideoPlayerTableViewCell.player.seek(to: .zero)
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
