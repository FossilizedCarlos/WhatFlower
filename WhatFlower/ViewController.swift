//
//  ViewController.swift
//  WhatFlower
//
//  Created by Carlos E. Barboza on 5/31/20.
//  Copyright © 2020 Fossilized Bits. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let flowerImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage into CIImage")
            }
            detect(image: flowerImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML model failed.")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(for: firstResult.identifier)
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try  handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }        
    }
    
    func requestInfo(for flowerName: String) {
        
        let formattedName = flowerName.replacingOccurrences(of: " ", with: "%20")
        //        let parameters : [String:String] = [
        //            "format" : "json",
        //            "action" : "query",
        //            "prop" : "extracts",
        //            "exintro" : "",
        //            "explaintext" : "",
        //            "titles" : flowerName,
        //            "redirects" : "1",
        //        ]
        let urlString = "\(wikipediaURl)?format=json&action=query&prop=extracts&titles=\(formattedName)&exintro&explaintext&redirects=true&indexpageids"
        AF.request(urlString).response { response in
                guard let wikiData = response.data else {
                    fatalError("Unable to get reponse data.")
                }
                
                guard let json = try? JSON(data: wikiData) else {
                    fatalError("Unable to convert data to JSON format.")
                }
                
                guard let pageId = json["query"]["pageids"][0].string else {
                    fatalError("Unable to get page id.")
                }
                
                guard let description = json["query"]["pages"][pageId]["extract"].string else {
                    fatalError("Unable to get description.")
                }
                
                print(description)
        }
    }
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
}

