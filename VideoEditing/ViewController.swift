//
//  ViewController.swift
//  VideoEditing
//
//  Created by Shaheryar Malik on 30/07/2023.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func pickVideoButtonTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)

        if let videoURL = info[.mediaURL] as? URL {
            let interval: TimeInterval = 30 // 30 seconds interval
            saveBlurredImagesFromVideo(videoURL: videoURL, interval: interval)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func saveBlurredImagesFromVideo(videoURL: URL, interval: TimeInterval) {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let duration = CMTimeGetSeconds(asset.duration)

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("BlurredImages")
        try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)

        for time in stride(from: 0, to: duration, by: interval) {
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            do {
                let image = try imageGenerator.copyCGImage(at: cmTime, actualTime: nil)
                let blurredImage = applyBlurEffect(to: UIImage(cgImage: image))
                let fileURL = outputURL.appendingPathComponent("image_\(Int(time)).png")
                if let data = blurredImage.pngData() {
                    try data.write(to: fileURL)
                }
            } catch {
                print("Error generating image at time \(time): \(error)")
            }
        }

        // Save images to the camera roll (optional)
        let imagePaths = try? FileManager.default.contentsOfDirectory(at: outputURL, includingPropertiesForKeys: nil, options: [])
        for imagePath in imagePaths ?? [] {
            if let data = try? Data(contentsOf: imagePath) {
                if let image = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
    }

    func applyBlurEffect(to image: UIImage) -> UIImage {
        let context = CIContext(options: nil)
        let inputImage = CIImage(image: image)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(8.0, forKey: kCIInputRadiusKey)

        if let outputImage = filter?.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        } else {
            return image
        }
    }
}

