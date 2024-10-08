//
//  VideoPlayerTableViewCell.swift
//  Video Collection Player
//
//  Created by Dikan Chen on 9/30/24.
//

import UIKit
import AVKit

protocol videoPlayerTableViewCellDelegate: AnyObject {
    func playButtonTapped(_ cell: VideoPlayerTableViewCell)
    func sliderValueChanged(_ cell: VideoPlayerTableViewCell, value: Float)
}

class VideoPlayerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    
    weak var delegate: videoPlayerTableViewCellDelegate?
    static var player = AVPlayer()
    var playerLayer: AVPlayerLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        VideoPlayerTableViewCell.player.pause()
        playerLayer?.removeFromSuperlayer()
    }
    
    func configure(with playerItem: AVPlayerItem) {
        if VideoPlayerTableViewCell.player.currentItem === playerItem {
            // If it's already associated, no need to replace the item
            print("PlayerItem is already associated with the player.")
        } else {
            // If it's not associated, replace the current player item with the new one
            VideoPlayerTableViewCell.player.replaceCurrentItem(with: playerItem)
            print("PlayerItem has been replaced in the player.")
        }
        playerLayer = AVPlayerLayer(player: VideoPlayerTableViewCell.player)
        playerLayer?.frame = contentView.bounds
        contentView.layer.insertSublayer(playerLayer!, at: 0)
        addPlayerObservers()
    }
    
    func configure(with videoURL: URL) {
        VideoPlayerTableViewCell.player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: VideoPlayerTableViewCell.player)
        
        playerLayer?.frame = contentView.bounds
        contentView.layer.insertSublayer(playerLayer!, at: 0)
        
        addPlayerObservers()
    }
    
    func playVideo() {
        VideoPlayerTableViewCell.player.play()
        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    
    func stopVideo() {
        VideoPlayerTableViewCell.player.pause()
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    @IBAction func playBtnTapped(_ sender: Any) {
        if VideoPlayerTableViewCell.player.timeControlStatus == .playing {
            stopVideo()
            print("pause video")
        } else {
            playVideo()
            print("play video")
        }
        delegate?.playButtonTapped(self)
    }
    
    @IBAction func sliderSwiped(_ sender: Any) {
        guard let duration = VideoPlayerTableViewCell.player.currentItem?.duration else { return }
        let totalSeconds = CMTimeGetSeconds(duration)
        let value = Float64(progressSlider.value) * totalSeconds
        
        let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
        VideoPlayerTableViewCell.player.seek(to: seekTime)
        
        delegate?.sliderValueChanged(self, value: progressSlider.value)
    }
    
    func addPlayerObservers() {
        let player = VideoPlayerTableViewCell.player
        guard let currentItem = player.currentItem else { return }
        
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 2), queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let duration = currentItem.duration
            guard duration.isNumeric, duration.seconds > 0 else { return }
            
            let currentTime = CMTimeGetSeconds(time)
            let progress = Float(currentTime / duration.seconds)
            print("player progress is \(progress)")
            self.progressSlider.value = progress
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
    }
    
    @objc func videoDidEnd() {
        VideoPlayerTableViewCell.player.seek(to: CMTime.zero)
        VideoPlayerTableViewCell.player.play()
    }
}
