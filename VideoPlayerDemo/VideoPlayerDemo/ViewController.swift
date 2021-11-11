//
//  ViewController.swift
//  VideoPlayerDemo
//
//  Created by mac on 09/11/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var lblCurrentTime: UILabel!
    @IBOutlet weak var lblDurationTime: UILabel!
    @IBOutlet weak var sliderTime: UISlider!

    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnMute: UIButton!
    @IBOutlet weak var videoView: UIView!

    public var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var isVideoPlaying = false

    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .large)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()
    
    lazy var pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "play")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.isHidden = true
        button.addTarget(self, action: #selector(onBtnPlay(_:)), for: .touchUpInside)

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        sliderTime.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        sliderTime.isUserInteractionEnabled = false
        setupPlayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }

    func setupPlayer() {
        activityIndicatorView.startAnimating()
//        let url = Bundle.main.url(forResource: "free", withExtension: "mp4")!
        let urlString =  "https://app.unikwork.com/instagram/videos/201912211438_10000_mine.mp4"

        if let url = Bundle.main.url(forResource: "free", withExtension: "mp4") {
            player = AVPlayer(url: url)
            player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
            player?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)

            onBtnPlayPause()
            addObserverToVideoisEnd()
            addTimeObserver()

            playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            videoView.layer.addSublayer(playerLayer)
            setupPlayButtonInsideVideoView()
        }
    }

    func addObserverToVideoisEnd() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerEndPlay), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { [weak self] time in
            guard let currentItem = self!.player.currentItem else {return}
            if self?.player.currentItem!.status == .readyToPlay {
                self?.sliderTime.minimumValue = 0
                self?.sliderTime.maximumValue = Float(currentItem.duration.seconds)
                self?.sliderTime.value = Float(currentItem.currentTime().seconds)
                self?.lblCurrentTime.text = currentItem.currentTime().durationText
            }
        }
    }

    func setupPlayButtonInsideVideoView() {
        videoView.addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: videoView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: videoView.centerYAnchor).isActive = true

        videoView.addSubview(pausePlayButton)
        pausePlayButton.centerXAnchor.constraint(equalTo: videoView.centerXAnchor).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: videoView.centerYAnchor).isActive = true
        pausePlayButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        pausePlayButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.someAction (_:)))
        self.videoView.addGestureRecognizer(gesture)
    }

    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                print("began")
                player.pause()
                break
                // handle drag began
            case .moved:
                print("moved")
                break
                // handle drag moved
            case .ended:
                if isVideoPlaying {
                    player.play()
                    self.pausePlayButton.isHidden = true
                } else {
                    player.pause()
                    self.pausePlayButton.isHidden = false
                }
                print("ended ")
                break
                // handle drag ended
            default:
                break
            }
        }
    }

    @objc func someAction(_ sender: UITapGestureRecognizer){
        print("view was clicked")
        onBtnPlayPause()
    }

    @objc func playerEndPlay() {
        onBtnPlayPause()
        print("Player ends playing video")
        player.seek(to: CMTime.zero)
        player.pause()
    }

    func onBtnPlayPause() {
        if isVideoPlaying {
            player.pause()
            btnPlay.setTitle("Play", for: .normal)
            pausePlayButton.setImage(UIImage(named: "play"), for: .normal)
            self.pausePlayButton.isHidden = false
        } else {
            player.play()
            btnPlay.setTitle("Pause", for: .normal)
            pausePlayButton.setImage(UIImage(named: "pause"), for: .normal)
        }
        isVideoPlaying = !isVideoPlaying

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
            if self.isVideoPlaying {
                self.pausePlayButton.isHidden = true
            }
        }
    }

    @IBAction func onBtnPlay(_ sender: Any) {
        onBtnPlayPause()
    }

    @IBAction func onbtnForward(_ sender: UIButton) {
        guard let duration = player.currentItem?.duration else {
            return
        }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 5.0
        if newTime < (CMTimeGetSeconds(duration) - 5.0) {
            let time: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
            player.seek(to: time)
        }
    }

    @IBAction func onBtnBackword(_ sender: UIButton) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 5.0

        if newTime < 0 {
            newTime = 0
        }

        let time: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
        player.seek(to: time)
    }

    @IBAction func sliderValueChange(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value*1000), timescale: 1000))
    }

    @IBAction func onBtnMute(_ sender: UIButton) {
        btnMute.isSelected.toggle()
        if btnMute.isSelected {
            player.isMuted = true
        } else {
            player.isMuted = false
        }
    }


    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0 {
            self.lblDurationTime.text = player.currentItem!.duration.durationText
        }

        if keyPath == "currentItem.loadedTimeRanges" {
//            pausePlayButton.isHidden = false
            sliderTime.isUserInteractionEnabled = true
            activityIndicatorView.stopAnimating()
        }
    }
}
