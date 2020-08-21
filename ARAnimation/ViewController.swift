//
//  ViewController.swift
//  ARAnimation
//
//  Created by Kenneth on 4/12/20.
//  Copyright © 2020 Kenneth. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Speech
import AVFoundation


class ViewController: UIViewController, ARSCNViewDelegate, SFSpeechRecognizerDelegate {
    
    
    //this is a google cloud function(serverless backend) that I created to handle query requests to dialogflow
    let url = URL(string: "https://us-central1-covid19-cloud-function.cloudfunctions.net/app/get-fulfillment")
    var timer : Timer?
    var audioPlayer = AVAudioPlayer()
    let audioEngine = AVAudioEngine()
    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask : SFSpeechRecognitionTask?
    var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    var animations = [String: CAAnimation]()
    var audioSource : SCNAudioSource!
    var node : SCNNode!
    let synthesizer = AVSpeechSynthesizer()
    var audioSession = AVAudioSession.sharedInstance()
    var inputNode : AVAudioInputNode?
    
    
    
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var transcribedText: UILabel!            //this shows the transcribed text as the user speaks
    
    
    override public func viewDidAppear(_ animated: Bool) {
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        //super.viewDidAppear(_ animated: Bool)
        
        speechRecognizer?.delegate = self
        
        // Make the authorization request
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // The authorization status results in changes to the
            // app’s interface, so process the results on the app’s
            // main queue.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Authorization granted by user")
                    
                case .denied:
                    print("Authorization denied")
                    
                case .restricted:
                    print("Authorization restricted")
                    
                case .notDetermined:
                    print("Authorization not determined")
                @unknown default:
                    fatalError()
                }
            }
        }
        
        //start long timer
        timer = Timer.scheduledTimer(timeInterval: 200, target: self, selector: #selector(self.didFinishTalk), userInfo: nil, repeats: false)
        do {
            try startRecording()
        } catch {
            print("could not call start recording function")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        
        audioPlayer.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        
        //load the DAE animation
        loadAnimations()
    }
    
    func loadAnimations () {
        
        // Load the character in the idle animation
        let idleScene = SCNScene(named: "art.scnassets/idleFixed.dae")!
        
        
        
        //This node will be parent of all the animation models
        node = SCNNode()
        
        // Add all the child nodes to the parent node
        for child in idleScene.rootNode.childNodes {
            node.addChildNode(child)
        }
        
        
        
        // Set up some properties
        node.position = SCNVector3(-1, -20, -20)
        node.scale = SCNVector3(0.1, 0.1, 0.1)
        //node.position = SCNVector3(-1, -120, -300)
        //node.scale = SCNVector3(1, 1, 0.5)
        //       node.position = SCNVector3(0, 0, 0)
        //        node.scale = SCNVector3(0, 0, 0)
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(node)
        
        // Load all the DAE animations
        loadAnimation(withKey: "talking", sceneName: "art.scnassets/TalkingFixed", animationIdentifier: "TalkingFixed-1")
    }
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            // The animation will keep looping until it is stopped
            animationObject.repeatCount = .greatestFiniteMagnitude
            // To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(0.5)
            animationObject.fadeOutDuration = CGFloat(0.2)
            
            // Store the animation for later use
            animations[withKey] = animationObject
        }
    }
    
    
    
    func playAnimation(key: String) {
        // Add the animation when its ready to start talking
        node.addAnimation(animations[key]!, forKey: key)
    }
    
    func stopAnimation(key: String) {
        // Stop the animation with a smooth transition of 0.5 secs
        node.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //set up the AR sceen view
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user if it fails
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}


//MARK: - setUpScreenView
extension ViewController {
    
    func setUpSceneView() {
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
        //.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
    }
}

//MARK: - Http Request to dialog flow and Audio Handling
extension ViewController : AVAudioPlayerDelegate{
    
    
    func makeRequest(userQuery: String){
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        let postString = "query="+userQuery
        request.httpBody = postString.data(using: String.Encoding.utf8);
        print("ABOUT TO MAKE REQUEST")
        // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            //print(response)
            // Convert HTTP Response Data to a String
            
            if let data = data {
                print(data)
                //respond back to user with the data
                self.respondBack(response: data);
            }
        }
        task.resume()
    }
    
    func respondBack(response : Data){
        
        //get or create an output file to store dialog flow responses
        let filename = getDocumentsDirectory().appendingPathComponent("output.wav")
        print(filename)
        
        do {
            //only write to it if audio is not currently playing (responding back to user)
            if !audioPlayer.isPlaying {
                print("audio player status: \(audioPlayer.isPlaying)")
             
                    try response.write(to: filename)                        //write to file
                
                    audioPlayer = try AVAudioPlayer(contentsOf: filename, fileTypeHint: AVFileType.wav.rawValue)
                    audioPlayer.delegate = self
                    audioPlayer.prepareToPlay()
                    audioPlayer.volume = 100
                    playAnimation(key: "talking")                          //set talking animation
                    audioPlayer.play()                                     //play the audio response
                
            }

            
        } catch {
            // if something goes wrong, then play the default response instead of crashing
            print("SOMETHING WENT WRONG!!")
            print("Error info: \(error)")
            let defaultResponse = Bundle.main.path(forResource: "default", ofType: "wav")
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: defaultResponse!))
                audioPlayer.delegate = self
                audioPlayer.prepareToPlay()
                audioPlayer.volume = 100
                playAnimation(key: "talking")                          //set talking animation
                audioPlayer.play()                                     //play the audio response
                
            } catch {
                print("could not call start recording function")
            }
            
        }
        
    }
    
    //this function gets the path of the app document directory
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    //this is a delegate function that gets triggered when the audio is done playing from the virtual assistant
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopAnimation(key: "talking")                                   //stop the animation
        print("VIRTUAL ASSISTANT DONE TALKING")
        do {
            try startRecording()                                        //re-enable recording of user input from the mic
            
        } catch {
            print("could not restart startRecording()")
        }
        
    }
    
    
    
}

//MARK: - Speech Recognition

extension ViewController{
    
    
        /*
            This function is responsible for starting the recording session and setting up the Speech Recognizer SDK
            as well as the Audio Engine
        */
        func startRecording() throws {
            print("START RECORDING CALLED")
            recognitionTask?.cancel()
            self.recognitionTask = nil
    
            
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    
            inputNode = audioEngine.inputNode
            inputNode?.removeTap(onBus: 0)
            let recordingFormat = inputNode?.outputFormat(forBus: 0)
            inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer:AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {fatalError("Unable to instantiate a SFSpeechAudioBuffer")}
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true
            recognitionRequest.contextualStrings = ["stats", "Alachua", "county", "Broward", "parish", "confirmed", "deaths", "land"]
//            if #available(iOS 13, *) {
//                if speechRecognizer?.supportsOnDeviceRecognition ?? false {
//                    recognitionRequest.requiresOnDeviceRecognition = true
//                }
//            }
    
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                /*
                    This get triggered whenever a speech is recognized.
                    It is updated in the UI transcribed text box and a timer is set to trigger if no speech is detected for 2 secs
                 */
                
                if let result = result {
                    DispatchQueue.main.async {
                        
                        let transcribedString = result.bestTranscription.formattedString                    //gets the best transcription
                        self.transcribedText.text = transcribedString
                        print("transcribed word: \(transcribedString)")
                        //reset timer
                        self.timer?.invalidate()
                        self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.didFinishTalk), userInfo: nil, repeats: false)
    
                    }
    
                    if result.isFinal {
                        print("--------TALKING DONE--------")
                    }
                    
                }
    
                if error != nil {
                    print("gets here")
                    self.audioEngine.stop()
                    self.inputNode?.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
    
            }
        }
    
    /*
        This function is called when the timer expires to signal that the user is done talking
     */
    
    @objc func didFinishTalk() throws {
        switchOffRecognition()
        timer?.invalidate()                                             //switch off any timer to avoid a second call
        print("USER DID FINISH TALKING")
        if let text = transcribedText.text {
            
            makeRequest(userQuery: text)                                //call the function that makes the network call to the google cloud function
            transcribedText.text = ""
            print("MADE REQUEST")
        }
        
    }
    
    func switchOffRecognition() {
        //this removes the speech recognition from the mic and releases alll resources held
        
        if audioEngine.isRunning {
            print("Audio engine active")
            recognitionRequest?.endAudio()
            audioEngine.stop()
            
            inputNode?.removeTap(onBus: 0)
            self.recognitionRequest = nil
            self.recognitionTask = nil
        }
    }
    
}

