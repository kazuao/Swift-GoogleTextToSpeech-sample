//
//  ViewController.swift
//  GoogleTextToSpeech-translate
//
//  Created by kazunori.aoki on 2021/12/10.
//

import UIKit

// ref: `https://medium.com/google-cloud/how-to-integrate-google-cloud-text-to-speech-api-into-your-ios-app-140ab7be42ae`

class ViewController: UIViewController {

    // MARK: UI
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var voiceGenderControl: UISegmentedControl!
    @IBOutlet weak var speakButton: UIButton!


    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        speakButton.setTitle("Speak", for: .normal)
    }


    // MARK: IBAction
    @IBAction func tapSpeakButton(_ sender: Any) {

        speakButton.setTitle("Speaking...", for: .normal)
        speakButton.isEnabled = false
        speakButton.alpha = 0.6

        var voiceType: VoiceType = .undefined
        let gender = voiceGenderControl.titleForSegment(at: voiceGenderControl.selectedSegmentIndex)
        if gender == "Female" {
            voiceType = .standardFemale
        } else if gender == "Male" {
            voiceType = .standardMale
        }

        SpeechService.shared.speak(text: textView.text, voiceType: voiceType) {
            print("finished")
            self.speakButton.setTitle("Speak", for: .normal)
            self.speakButton.isEnabled = true
            self.speakButton.alpha = 1
        }
    }
}
