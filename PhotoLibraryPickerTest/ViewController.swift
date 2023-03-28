//
//  ViewController.swift
//  PhotoLibraryPickerTest
//
//  Created by Ric Santos on 24/3/2023.
//

import UIKit
import PhotosUI
import AVKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pickVideoButton = UIButton()
        pickVideoButton.backgroundColor = UIColor.systemBlue
        pickVideoButton.setTitle("Pick Video", for: .normal)
        pickVideoButton.addTarget(self, action: #selector(pickVideoButtonPressed), for: .touchUpInside)
        pickVideoButton.frame = CGRect(x: 20, y: 60, width: 200, height: 40)
        pickVideoButton.layer.cornerRadius = 8
        self.view.addSubview(pickVideoButton)
    }
    
    @objc func pickVideoButtonPressed() {
        self.requestAuthorization(completion: { granted in
            guard granted else {
                print("Authorization not granted")
                return
            }
            
            DispatchQueue.main.async {
                self.pickVideo()
            }
        })
    }
    
    func requestAuthorization(completion: @escaping ((Bool) -> Void)) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            print("Authorization status: \(status.debugDescription)")
            switch status {
            case .authorized:
                completion(true)
            case .limited:
                completion(false)
            default:
                completion(false)
            }
        }
    }
    
    func pickVideo() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 1
        config.filter = .videos
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        self.present(picker, animated: true, completion: nil)
    }
    
    func handlePickVideoResult(url: URL?, error: Error?) {
        if let url {
            print("✅ Picked Video with Url - \(url)")
            let playerViewController = AVPlayerViewController()
            playerViewController.player = AVPlayer(url: url)
            self.present(playerViewController, animated: true, completion: nil)
        } else if let error {
            print("🔥 Picker ERROR - \(error)")
        }
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let wrapUp: ((URL?, Error?) -> Void) = { [weak self] url, error in
            DispatchQueue.main.async {
                picker.dismiss(animated: true)
                self?.handlePickVideoResult(url: url, error: error)
            }
        }
        
        guard let result = results.first else {
            wrapUp(nil, nil)
            return
        }
        
        print("Picker result: \(result)")
        guard let typeIdentifier = result.itemProvider.registeredTypeIdentifiers.first else {
            print("No type identifier, aborting")
            wrapUp(nil, nil)
            return
        }
        print("Type identifier: \(typeIdentifier)")
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { (url, error) in
            if let error {
                print("Load file representation ERROR - \(error)")
                wrapUp(nil, error)
                return
            }
            guard let url else {
                print("No URL - shouldn't happen")
                wrapUp(nil, nil)
                return
            }
            print("Load file representation Url - \(url)")
            
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            if !fileExists {
                print("🔥 File doesn't exist at path")
                // Uncomment next 2 lines to return early with the picked Url (which doesn't play)
                //wrapUp(url, nil)
                //return
            } else {
                print("✅ File does exist!")
            }
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory: String = paths[0]
            
            let tempDirectoryUrl = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("temp-dir")
            
            do {
                try FileManager.default.createDirectory(atPath: tempDirectoryUrl.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("ERROR: \(error.localizedDescription)")
                wrapUp(nil, error)
            }
            
            let destinationUrl = tempDirectoryUrl.appendingPathComponent(url.lastPathComponent)
            print("Will attempt to copy file to url: \(destinationUrl)")
            
            do {
                // Important! You must copy the file url that you receive to a url in your sandbox, otherwise the contents of the file will disappear when this closure is exited.
                try FileManager.default.copyItem(at: url, to: destinationUrl)
            } catch {
                print("ERROR: Unable to copy file - \(error)")
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain {
                    print("NSCocoaErrorDomain, code: \(nsError.code)")
                    if nsError.code == NSFileWriteFileExistsError {
                        print("File already exists!")
                        wrapUp(destinationUrl, error)
                        return
                    }
                }
                wrapUp(nil, error)
                return
            }
            
            print("🎉 Success we copied the file")
            wrapUp(destinationUrl, error)
        }
    }
}

extension PHAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined:
            return "Not determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .limited:
            return "Limited"
        @unknown default:
            return "Unknown"
        }
    }
}
