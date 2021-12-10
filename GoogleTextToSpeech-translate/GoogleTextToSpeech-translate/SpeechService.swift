//
//  SpeechService.swift
//  GoogleTextToSpeech-translate
//
//  Created by kazunori.aoki on 2021/12/10.
//

import UIKit
import AVFoundation

enum VoiceType: String {
    case undefined
    case standardFemale = "ja-JP-Standard-A"
    case standardMale = "ja-JP-Standard-C"
}

let apiUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"

class SpeechService: NSObject {
    static let shared = SpeechService()

    private(set) var busy = false

    private var player: AVAudioPlayer?
    private var completionHandler: (() -> ())?

    func speak(text: String, voiceType: VoiceType = .standardFemale, completion: @escaping () -> ()) {

        guard !busy else {
            print("Speech Service busy!")
            return
        }

        busy = true

        DispatchQueue.global(qos: .background).async {

            let postData = self.buildPostData(text: text, voiceType: voiceType)
            let headers = ["X-Goog-Api-Key": Config.google_api_key,
                           "Content-Type": "application/json; charset=utf-8"]
            let response = self.makePostRequest(url: apiUrl, postData: postData, headers: headers)

            guard let audioContent = response["audioContent"] as? String else {
                print("Invalid response: \(response)")
                self.busy = false

                DispatchQueue.main.async {
                    completion()
                }
                return
            }

            guard let audioData = Data(base64Encoded: audioContent) else {
                self.busy = false

                DispatchQueue.main.async {
                    completion()
                }
                return
            }

            DispatchQueue.main.async {
                self.completionHandler = completion
                self.player = try! AVAudioPlayer(data: audioData)
                self.player?.delegate = self
                self.player!.play()
            }
        }
    }
}


private extension SpeechService {

    func buildPostData(text: String, voiceType: VoiceType) -> Data {

        var voiceParams: [String: Any] = [
            "languageCode": "ja-JP"
        ]

        if voiceType != .undefined {
            voiceParams["name"] = voiceType.rawValue
        }

        let params: [String: Any] = [
            "input": [
                "text": text
            ],
            "voice": voiceParams,
            "audioConfig": [
                "audioEncoding": "LINEAR16"
            ]
        ]

        let data = try! JSONSerialization.data(withJSONObject: params)
        return data
    }

    func makePostRequest(url: String, postData: Data,
                         headers: [String: String] = [:]) -> [String: AnyObject] {

        var dict = [String: AnyObject]()

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = postData

        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("Error", error.localizedDescription)
            }

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                dict = json
            }

            semaphore.signal()
        }

        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        return dict
    }
}

extension SpeechService: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player?.delegate = nil
        self.player = nil
        self.busy = false

        self.completionHandler!()
        self.completionHandler = nil
    }
}
