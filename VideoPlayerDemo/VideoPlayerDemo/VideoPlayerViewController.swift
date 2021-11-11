//
//  AboutViewController.swift
//  CCSIMobile
//
//  Created by mac on 09/11/21.
//  Copyright © 2021 Turkcell. All rights reserved.
//
import AVFoundation
import UIKit

final class VideoPlayerViewController: UIViewController {
    // MARK: - IBOutlet
    @IBOutlet weak private var lblCurrentTime: UILabel!
    @IBOutlet weak private var lblDurationTime: UILabel!
    @IBOutlet weak private var sliderTime: UISlider!

    @IBOutlet weak private var btnMute: UIButton!
    @IBOutlet weak private var videoView: UIView!

    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var imgTopShadow: UIImageView!
    @IBOutlet weak var viewPlayerDetails: UIView!

    // MARK: - Properties
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var isVideoPlaying = false
    private var isPlayerViewHide = true
    private var puseTime: CMTime = .zero
    private var timer: Timer?

    private let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView()
        aiv.tintColor = .white
        aiv.color = .white
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()

    private lazy var pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "ic_Play")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.isHidden = false
        button.addTarget(self, action: #selector(onBtnPlay(_:)), for: .touchUpInside)

        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0 {
            self.lblDurationTime.text = player.currentItem!.duration.durationText
        }
        
        if keyPath == "currentItem.loadedTimeRanges" {
            sliderTime.isUserInteractionEnabled = true
            activityIndicatorView.stopAnimating()
            player.play()
        }
    }

    // MARK: - Function
    private func setupUI() {
        setupVideoTimeSlider()
        setupPlayer()
    }

    private func setupVideoTimeSlider() {
        let sliderTimeimgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        sliderTimeimgView.image = UIImage(named: "ic_video_thabh")
        sliderTime.setThumbImage(sliderTimeimgView.image, for: .normal)
        sliderTime.setThumbImage(sliderTimeimgView.image, for: .selected)

        sliderTime.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        sliderTime.isUserInteractionEnabled = false
    }

    private func setupPlayer() {
        activityIndicatorView.startAnimating()
        let urlString =  "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
//        URL(string: urlString)  Bundle.main.url(forResource: "free", withExtension: "mp4")
        if let url = Bundle.main.url(forResource: "free", withExtension: "mp4") {
            player = AVPlayer(url: url)
            player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
            player?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)

            onBtnPlayPause()

            addTimeObserver()
            addObserverToVideoisEnd()

            playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            videoView.layer.addSublayer(playerLayer)
            setupPlayButtonInsideVideoView()
        }
    }

    private func addObserverToVideoisEnd() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerEndPlay), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { [weak self] time in
            guard let currentItem = self!.player.currentItem else {return}
            if self?.player.currentItem!.status == .readyToPlay {
                self?.sliderTime.minimumValue = 0
                self?.sliderTime.maximumValue = Float(currentItem.duration.seconds)
                self?.sliderTime.value = Float(time.seconds)
                self?.lblCurrentTime.text = time.durationText
            }
        }
    }

    private func setupPlayButtonInsideVideoView() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.someAction(_:)))
        self.viewMain.addGestureRecognizer(gesture)

        videoView.addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: videoView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: videoView.centerYAnchor).isActive = true

        viewMain.addSubview(pausePlayButton)
        pausePlayButton.centerXAnchor.constraint(equalTo: viewMain.centerXAnchor).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: viewMain.centerYAnchor).isActive = true
        pausePlayButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        pausePlayButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private func onBtnPlayPause() {
        if isVideoPlaying {
            player.pause()
            pausePlayButton.setImage(UIImage(named: "ic_Play"), for: .normal)
            isVideoPlaying = false
        } else {
            player.play()
            pausePlayButton.setImage(UIImage(named: "ic_Pause"), for: .normal)
            isVideoPlaying = true
        }
        self.hideshowPlayerView()
    }

    private func hideshowPlayerView(isViewTouch: Bool = false) {

        if isPlayerViewHide {
            UIView.transition(with: self.viewPlayerDetails, duration: 0.6,
                              options: .transitionCrossDissolve,
                              animations: {
                                self.pausePlayButton.isHidden = false
                                self.imgTopShadow.isHidden = false
                                self.viewPlayerDetails.isHidden = false
                                self.isPlayerViewHide = false
                              })
        } else {
            if isViewTouch {
                UIView.transition(with: self.viewPlayerDetails, duration: 0.6,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.pausePlayButton.isHidden = true
                                    self.imgTopShadow.isHidden = true
                                    self.viewPlayerDetails.isHidden = true
                                    self.isPlayerViewHide = true
                                  })
            }

        }
        self.timer?.invalidate()
        if isPlayerViewHide == false && isVideoPlaying {
            self.timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] timer in
                if self?.isPlayerViewHide == false && self!.isVideoPlaying {
                    UIView.transition(with: self!.viewPlayerDetails, duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        self?.pausePlayButton.isHidden = true
                                        self?.imgTopShadow.isHidden = true
                                        self?.viewPlayerDetails.isHidden = true
                                        self?.isPlayerViewHide = true
                                      })
                }
            }
        }
    }

    // MARK: - IBAction
    @IBAction private func sliderValueChange(_ sender: UISlider) {
        let seekingCM = CMTimeMake(value: Int64(sender.value * Float(puseTime.timescale)), timescale: puseTime.timescale)
        lblCurrentTime.text = seekingCM.durationText
        player.seek(to: seekingCM)
    }

    @IBAction private func onBtnMute(_ sender: UIButton) {
        if isPlayerViewHide == false {
            timer?.invalidate()
            hideshowPlayerView()
        }
        btnMute.isSelected.toggle()
        if btnMute.isSelected {
            btnMute.isSelected = true
            player.isMuted = true
        } else {
            btnMute.isSelected = false
            player.isMuted = false
        }
    }

    // MARK: - Event
    @objc private func onBtnPlay(_ sender: Any) {
        onBtnPlayPause()
    }

    @objc private func onSliderValChanged(slider: UISlider, event: UIEvent) {
        self.timer?.invalidate()
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                player.pause()
                guard let currentTime = player.currentItem?.currentTime() else {return}
                self.puseTime = currentTime
            case .moved:
                break
            case .ended:
                if isVideoPlaying {
                    player.play()
                } else {
                    player.pause()
                }
                self.hideshowPlayerView()
            default:
                break
            }
        }

    }

    @objc private func someAction(_ sender: UITapGestureRecognizer) {
        self.hideshowPlayerView(isViewTouch: true)
    }

    @objc private func playerEndPlay() {
        onBtnPlayPause()
        isPlayerViewHide = true
        hideshowPlayerView()
        player.seek(to: CMTime.zero)
    }

}

extension CMTime {
    var durationText: String {
        let totalSeconds = CMTimeGetSeconds(self)
        let hours: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
