//
//  ViewController.swift
//  Steganography
//
//  Created by Juan David Torres  on 29/04/21.
//

import UIKit

class HideViewController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var buttonChoose: UIButton!
    @IBOutlet weak var buttonCamera: UIButton!
    @IBOutlet weak var imageHide: UIImageView!
    @IBOutlet weak var buttonHide: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    var imageToHide:UIImage? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        textView.text = "Ingresa el mensaje"
        textView.textColor = UIColor.lightGray
        
        buttonChoose.clipsToBounds = true
        buttonChoose.layer.cornerRadius = 10
        
        buttonCamera.clipsToBounds = true
        buttonCamera.layer.cornerRadius = 10
        
        buttonHide.clipsToBounds = true
        buttonHide.layer.cornerRadius = 10
        
        self.setupHideKeyboardOnTap()
        
        buttonHide.isHidden = true
        textView.isHidden = true
        
        textView!.layer.borderWidth = 1
        textView!.layer.borderColor = UIColor.lightGray.cgColor
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 10;
        
    }
    func setupHideKeyboardOnTap() {
            self.view.addGestureRecognizer(self.endEditingRecognizer())
            self.navigationController?.navigationBar.addGestureRecognizer(self.endEditingRecognizer())
    }

    
    private func endEditingRecognizer() -> UIGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(self.view.endEditing(_:)))
        tap.cancelsTouchesInView = false
        return tap
    }
    
    @IBAction func clickButtonChoose(_ sender: Any) {
        presentPicker(with: .photoLibrary)
    }
    @IBAction func clickButtonCamera(_ sender: Any) {
        presentPicker(with: .camera)
    }
    @IBAction func clickButtonHide(_ sender: Any) {
        hideMessage()
    }
    
    func presentPicker(with sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
        
    }
    
    //Message
    func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Ingresa el mensaje"
            textView.textColor = UIColor.lightGray
            buttonHide.isHidden = true
        }else{
            buttonHide.isHidden = false
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        let image = info[.originalImage] as! UIImage
        imageHide.image = image
        imageToHide = image
        
        
        textView.isHidden = false
    }
    
    func hideMessage(){
        let messageToHide = textView.text
        let binaryData = Data(messageToHide!.utf8)
        let stringOf01 = binaryData.reduce("") { (acc, byte) -> String in
            var transformed = String(byte, radix: 2)
            while transformed.count < 8 {
                transformed = "0" + transformed
            }
            return acc + " " + transformed
        }
//        https://stackoverflow.com/questions/31661023/change-color-of-certain-pixels-in-a-uiimage
        print(stringOf01[0])
        
        let cGImageToHide = imageToHide?.cgImage;
        guard let pixelData = cGImageToHide?.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else { return }
        print(data[0]);
    }

}
extension CGImage {
    func pixel(x: Int, y: Int) -> (r: Int, g: Int, b: Int)? { // swiftlint:disable:this large_tuple
        guard let pixelData = dataProvider?.data,
            let data = CFDataGetBytePtr(pixelData) else { return nil }

        let pixelInfo = ((width  * y) + x ) * 4

        let red = Int(data[pixelInfo])         // If you need this info, enable it
        let green = Int(data[(pixelInfo + 1)]) // If you need this info, enable it
        let blue = Int(data[pixelInfo + 2])    // If you need this info, enable it
         // I need only this info for my maze game

        return (red, green, blue)
    }
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}