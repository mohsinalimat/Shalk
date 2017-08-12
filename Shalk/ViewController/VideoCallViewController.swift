//
//  VideoCallViewController.swift
//  Shalk
//
//  Created by Nick Lee on 2017/8/6.
//  Copyright © 2017年 nicklee. All rights reserved.
//

import UIKit
import Quickblox
import QuickbloxWebRTC

class VideoCallViewController: UIViewController {

    var hour = 0

    var minute = 0

    var second = 0

    var secondTimer: DispatchSourceTimer?

    var minuteTimer: DispatchSourceTimer?

    var hourTimer: DispatchSourceTimer?

    var location = CGPoint(x: 0, y: 0)

    var isCameraEnabled = true

    var isMicrophoneEnabled = true

    let rtcManager = QBRTCClient.instance()

    var videoCapture: QBRTCCameraCapture?

    let qbManager = QBManager.shared

    @IBOutlet weak var timeLabel: UILabel!

    @IBOutlet weak var remoteVideoView: QBRTCRemoteVideoView!

    @IBOutlet weak var localVideoView: UIView!

    @IBOutlet weak var outletCamera: UIButton!

    @IBOutlet weak var outletMicrophone: UIButton!

    @IBAction func btnRotateCamera(_ sender: UIButton) {

        let position = self.videoCapture?.position

        switch position! {

        case .back:

            self.videoCapture?.position = .front

            break

        case .front:

            self.videoCapture?.position = .back

            break

        default: break

        }

    }

    @IBAction func btnCamera(_ sender: UIButton) {

        if isCameraEnabled {

            // MARK: User disabled the camera.

            isCameraEnabled = false

            outletCamera.setImage(UIImage(named: "icon-nocamera.png"), for: .normal)

            QBManager.shared.session?.localMediaStream.videoTrack.isEnabled = false

            self.localVideoView.isHidden = true

        } else {

            // MARK: User enabled the camera.

            isCameraEnabled = true

            outletCamera.setImage(UIImage(named: "icon-camera.png"), for: .normal)

            QBManager.shared.session?.localMediaStream.videoTrack.isEnabled = true

            self.localVideoView.isHidden = false

        }

    }

    @IBAction func btnMicrophone(_ sender: UIButton) {

        if isMicrophoneEnabled {

            // MARK: User muted the local microphone

            isMicrophoneEnabled = false

            outletMicrophone.setImage(UIImage(named: "icon-nomic.png"), for: .normal)

            qbManager.session?.localMediaStream.audioTrack.isEnabled = false

        } else {

            // MARK: User enabled the local microphone

            isMicrophoneEnabled = true

            outletMicrophone.setImage(UIImage(named: "icon-mic.png"), for: .normal)

            qbManager.session?.localMediaStream.audioTrack.isEnabled = true

        }

    }

    @IBAction func btnEndCall(_ sender: UIButton) {

        self.dismiss(animated: true, completion: nil)

        QBManager.shared.handUpCall()

        UserManager.shared.isConnected = false

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        localVideoView.center = CGPoint(x: 0, y: 0)

        rtcManager.add(self)

        if UserManager.shared.callType == .video {

            videoPreparation()

            QBManager.shared.acceptCall()

        } else {

            guard
                let qbID = UserManager.shared.opponent?.quickbloxId,
                let qbIDInteger = Int(qbID),
                let opponentID = [qbIDInteger] as? [NSNumber] else { return }

            QBManager.shared.session = QBRTCClient.instance().createNewSession(withOpponents: opponentID, with: .video)

            videoPreparation()

            UserManager.shared.startVideoCall()

        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))

        localVideoView.addGestureRecognizer(pan)

    }

    func handlePan(_ recognizer: UIPanGestureRecognizer) {

        let point = recognizer.location(in: self.view)

        localVideoView.center = point

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.stopTimer()

    }

    func videoPreparation() {

        let videoFormat = QBRTCVideoFormat.init()

        videoFormat.frameRate = 30

        videoFormat.pixelFormat = QBRTCPixelFormat.format420f

        videoFormat.width = 640

        videoFormat.height = 480

        self.videoCapture = QBRTCCameraCapture.init(videoFormat: videoFormat, position: AVCaptureDevicePosition.front)

        QBManager.shared.session?.localMediaStream.videoTrack.videoCapture = self.videoCapture

        self.videoCapture!.previewLayer.frame = self.localVideoView.bounds

        self.videoCapture!.startSession()

        self.localVideoView.layer.insertSublayer(videoCapture!.previewLayer, at: 0)

    }

}

// MARK: Timer setting
extension VideoCallViewController {

    func configTimer() {

        let timerQueue = DispatchQueue(label: "timer", attributes: .concurrent)

        secondTimer?.cancel()

        secondTimer = DispatchSource.makeTimerSource(queue: timerQueue)

        secondTimer?.scheduleRepeating(deadline: .now(), interval: 1.0, leeway: .microseconds(10))

        secondTimer?.setEventHandler {

            if self.second == 59 {

                self.second = 0

            } else {

                self.second += 1

            }

            self.timeLabel.text = "\(self.hour.addLeadingZero()) : \(self.minute.addLeadingZero()) : \(self.second.addLeadingZero())"

        }

        secondTimer?.resume()

        minuteTimer?.cancel()

        minuteTimer = DispatchSource.makeTimerSource(queue: timerQueue)

        minuteTimer?.scheduleRepeating(deadline: .now(), interval: 60.0, leeway: .microseconds(10))

        minuteTimer?.setEventHandler {

            if self.minute == 59 {

                self.minute = 0

            } else {

                self.minute += 1

            }

            self.timeLabel.text = "\(self.hour.addLeadingZero()) : \(self.minute.addLeadingZero()) : \(self.second.addLeadingZero())"

        }

        minuteTimer?.resume()

        hourTimer?.cancel()

        hourTimer = DispatchSource.makeTimerSource(queue: timerQueue)

        hourTimer?.scheduleRepeating(deadline: .now(), interval: 3600.0, leeway: .microseconds(10))

        hourTimer?.setEventHandler {

            self.hour += 1

            self.timeLabel.text = "\(self.hour.addLeadingZero()) : \(self.minute.addLeadingZero()) : \(self.second.addLeadingZero())"

        }
    }

    func stopTimer() {

        secondTimer?.cancel()

        secondTimer = nil

        minuteTimer?.cancel()

        minuteTimer = nil

        hourTimer?.cancel()

        hourTimer = nil

        second = 0

        minute = 0

        hour = 0

    }
}

extension VideoCallViewController: QBRTCClientDelegate {

    // MARK: 連線確定與該使用者進行連接
    func session(_ session: QBRTCBaseSession, connectedToUser userID: NSNumber) {

//        self.configTimer()

    }

    func session(_ session: QBRTCSession, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack, fromUser userID: NSNumber) {

        // MARK: Received remote video track

        self.remoteVideoView.setVideoTrack(videoTrack)

        videoTrack.isEnabled = true

    }

}
