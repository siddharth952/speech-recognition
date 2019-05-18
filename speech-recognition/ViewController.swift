//
//  ViewController.swift
//  speech-recognition
//
//  Created by Siddharth Sen on 18/05/19.
//  Copyright © 2019 Siddharth Sen. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import AVKit

class ViewController: UIViewController {

    //Outlets
    @IBOutlet weak var recordStart: UIButton!
    @IBOutlet weak var lbl: UILabel!
    
    //Variables
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask : SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.speechSetup()
    }
    
    //Action for text to speech
    @IBAction func converttext(_ sender: Any) {
        
        let string = lbl.text
        let utterance = AVSpeechUtterance(string: string ?? "Please enter some text.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
        
    }
    
    //Action for speech to text
    @IBAction func convertspeech(_ sender: Any) {
        
        if audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.recordStart.isEnabled = false
            self.recordStart.setTitle("Start Recording", for: .normal)
        } else {
            self.startRecording()
            self.recordStart.setTitle("Stop Recording", for: .normal)
        }
    }
    
    //Methods
    func speechSetup(){
        self.recordStart.isEnabled = false
        self.speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition.")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device.")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized.")
            }
            OperationQueue.main.addOperation() {
                self.recordStart.isEnabled = isButtonEnabled
            }
        }
    }
    
    func startRecording() {
        // Clear all previous session data and cancel tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        // Create instance of audio session to record voice.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
    
        recognitionRequest.shouldReportPartialResults = true
        
        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.lbl.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordStart.isEnabled = true
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        self.audioEngine.prepare()
        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        self.lbl.text = "Say something, I'm listening! :)"
    }
}

