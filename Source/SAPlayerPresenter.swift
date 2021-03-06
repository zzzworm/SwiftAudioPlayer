//
//  SAPlayerPresenter.swift
//  SwiftAudioPlayer
//
//  Created by Tanha Kabir on 2019-01-29.
//  Copyright © 2019 Tanha Kabir, Jon Mercer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import AVFoundation
import MediaPlayer

class SAPlayerPresenter {
    weak var delegate: SAPlayerDelegate?
    var shouldPlayImmediately = false //for auto-play
    
    var needle: Needle?
    var duration: Duration?
    
    private var key: String?
    private var isPlaying = false
    private var mediaInfo: SALockScreenInfo?
    
    private var urlKeyMap: [Key: URL] = [:]
    
    var durationRef:UInt = 0
    var needleRef:UInt = 0
    var playingStatusRef:UInt = 0
    
    init(delegate: SAPlayerDelegate?) {
        self.delegate = delegate
        
        delegate?.setLockScreenControls(presenter: self)
        
        prepareNextEpisodeToPlay()
    }
    
    func getUrl(forKey key: Key) -> URL? {
        return urlKeyMap[key]
    }
    
    func addUrlToKeyMap(_ url: URL) {
        urlKeyMap[url.key] = url
    }
    
    func handlePlayAudio(withRemoteUrl url: URL) {
        AudioClockDirector.shared.detachFromChangesInDuration(withID: durationRef)
        AudioClockDirector.shared.detachFromChangesInNeedle(withID: needleRef)
        AudioClockDirector.shared.detachFromChangesInPlayingStatus(withID: playingStatusRef)
        
        self.key = url.key
        
        if let savedUrl = AudioDataManager.shared.getPersistedUrl(withRemoteURL: url) {
            self.key = savedUrl.key
            urlKeyMap[savedUrl.key] = url
            delegate?.startAudioDownloaded(withSavedUrl: savedUrl)
        } else {
            urlKeyMap[url.key] = url
            delegate?.startAudioStreamed(withRemoteUrl: url)
        }
        
        durationRef = AudioClockDirector.shared.attachToChangesInDuration(closure: { [weak self] (key, duration) in
            guard let self = self else { throw DirectorError.closureIsDead }
            guard key == self.key else {
                Log.debug("misfire expected key: \(self.key ?? "none") payload key: \(key)")
                return
            }
            
            self.delegate?.updateLockscreenPlaybackDuration(duration: duration)
            self.duration = duration
            
            if let info = self.mediaInfo {
                self.delegate?.setLockScreenInfo(withMediaInfo: info, duration: duration)
            }
        })
        
        needleRef = AudioClockDirector.shared.attachToChangesInNeedle(closure: { [weak self] (key, needle) in
            guard let self = self else { throw DirectorError.closureIsDead }
            guard key == self.key else {
                Log.debug("misfire expected key: \(self.key ?? "none") payload key: \(key)")
                return
            }
            
            self.needle = needle
            self.delegate?.updateLockscreenElapsedTime(needle: needle)
        })
        
        playingStatusRef = AudioClockDirector.shared.attachToChangesInPlayingStatus(closure: { [weak self] (key, isPlaying) in
            guard let self = self else { throw DirectorError.closureIsDead }
            guard key == self.key else {
                Log.debug("misfire expected key: \(self.key ?? "none") payload key: \(key)")
                return
            }
            
            self.isPlaying = isPlaying
        })
    }
    
    func handleLockscreenInfo(info: SALockScreenInfo) {
        self.mediaInfo = info
    }
}

//MARK:- Used by outside world including:
// SPP, lock screen, directors
extension SAPlayerPresenter {
    func handlePause() {
        delegate?.pauseEngine()
    }
    
    func handlePlay() {
        delegate?.playEngine()
    }
    
    func handleTogglePlayingAndPausing() {
        if isPlaying {
            handlePause()
        } else {
            handlePlay()
        }
    }
    
    func handleSkipForward() {
        guard let forward = delegate?.skipForwardSeconds else { return }
        handleSeek(toNeedle: (needle ?? 0) + forward)
    }
    
    func handleSkipBackward() {
        guard let backward = delegate?.skipForwardSeconds else { return }
        handleSeek(toNeedle: (needle ?? 0) - backward)
    }
    
    func handleSeek(toNeedle needle: Needle) {
        delegate?.seekEngine(toNeedle: needle)
    }
    
    func handleSetSpeed(withMultiple: Double) {
        delegate?.setSpeedEngine(withMultiple: withMultiple)
    }
}

//MARK:- For lock screen
extension SAPlayerPresenter {
    func getIsPlaying() -> Bool {
        return isPlaying
    }
}

//MARK:- AVAudioEngineDelegate
extension SAPlayerPresenter: AudioEngineDelegate {
    func didError() {
        Log.monitor("We should have handled engine error")
    }
    
    func didEndPlaying() {
        // TODO
//        playNextEpisode()
    }
}

//MARK:- Autoplay
//FIXME: This needs to be refactored
extension SAPlayerPresenter {
    func prepareNextEpisodeToPlay() {
        // TODO
    }
}
