//
//  Decoder.swift
//  Steganography
//
//  Created by Sandra Román on 20/05/21.
//

import UIKit

let DATA_PREFIX = "<m>"
let DATA_SUFFIX = "</m>"
let INFO_LENGTH = BYTES_OF_LENGTH * BITS_PER_COMPONENT

class Decoder {
    private var currentShift: Int?
    private var bitsCharacter: Int?
    private var text: String?
    private var step = Int()
    private var length = Int()
    
    func decodeStegoImage(image: UIImage, error: inout NSError?) -> String? {
        var data: Data? = nil
        
        if hasDataInImage(image: image) {
            let base64 = substring(string: text, prefix: DATA_PREFIX, suffix: DATA_SUFFIX)
            data = Data(base64Encoded: base64!, options: Data.Base64DecodingOptions(rawValue: 0))
        } else {
            error = NSError(domain: "ISStegoErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey : "There is no data in image"])
        }
        
        return data != nil ? String(data: data!, encoding: .utf8)! : ""
    }
    
    private func hasDataInImage(image: UIImage) -> Bool {
        let inputCGImage: CGImage = image.cgImage!
        let width: Int = inputCGImage.width
        let height: Int = inputCGImage.height
        
        let size: Int = height * width
        let pixels = UnsafeMutablePointer<Int>.allocate(capacity: size)
        
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()

        let context: CGContext = CGContext(data: pixels,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: BITS_PER_COMPONENT,
                                           bytesPerRow: BYTES_PER_PIXEL * width,
                                           space: colorSpace,
                                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        searchDataInPixels(pixels, withSize: size)
        
        pixels.deallocate()
        
        return hasData()
    }
    
    private func searchDataInPixels(_ pixels: UnsafeMutablePointer<Int>, withSize size: Int) {
        reset()
        
        var pixelPosition: Int = 0
        
        while pixelPosition < INFO_LENGTH {
            getDataWithPixel(pixels[pixelPosition])
            pixelPosition += 1
        }
        
        reset()
        
        let pixelsToHide: Int = length * BITS_PER_COMPONENT
        
        let ratio: Double = Double((size - pixelPosition) / pixelsToHide)
        
        let salt: Int = Int(ratio)
        
        while pixelPosition <= size {
            getDataWithPixel(pixels[pixelPosition])
            pixelPosition += salt
            
            if(contains(string: text, substring: DATA_SUFFIX)) {
                break
            }
        }
    }
    
    private func reset() {
        currentShift = INITIAL_SHIFT
        bitsCharacter = 0
    }
    
    private func getDataWithPixel(_ pixel: Int) {
        getDataWithColor(color(pixel, shift: colorToStep(step: step)))
    }
    
    private func getDataWithColor(_ color: Int) {
        let bit: Int = color & 1
        bitsCharacter = (bit << currentShift!) | bitsCharacter!
        if currentShift == 0 {
            if(step < INFO_LENGTH) {
                getLength()
            } else {
                getCharacter()
            }
            currentShift = INITIAL_SHIFT
        } else {
            currentShift! -= 1
        }
        step += 1
    }
    
    private func getLength() {
        length = addBits(length, bitsCharacter!, shift: step % (BITS_PER_COMPONENT - 1))
        bitsCharacter = 0
    }
    
    private func getCharacter() {
        let character: String = String(Character(UnicodeScalar(bitsCharacter!)!))
        if text != nil {
            text! += character
        } else {
            text = character
        }
    }
    
    private func hasData() -> Bool {
        if text == nil {
            return false
        }
        return text!.length > 0 && contains(string: text, substring: DATA_PREFIX) && contains(string: text, substring: DATA_SUFFIX)
    }
    
    private func contains(string: String?, substring: String) -> Bool {
        if string == nil {
            return false
        }
        let string = string! as NSString
        let range: NSRange? = string.range(of: substring, options: .caseInsensitive)
        if range == nil {
            return false
        }
        if string.range(of: substring, options: .caseInsensitive).length != 0 {
            return true
        }
        return false
    }
    
    private func mask8(_ x: Int) -> Int {
        return x & 0xFF
    }
    
    private func addBits(_ number1: Int, _ number2: Int, shift: Int) -> Int {
        return number1 | mask8(number2) << 8 * shift
    }
    
    private func color(_ x: Int, shift: Int) -> Int {
        return mask8(x >> 8 * shift)
    }
    
    private func substring(string: String?, prefix: String, suffix: String) -> String? {
        let string: NSString? = string as NSString?
        var substring: String? = nil
        
        if string != nil {
            let prefixRange: NSRange? = string!.range(of: prefix)
            
            if prefixRange != nil {
                let suffixRange: NSRange? = string!.range(of: suffix)
                
                if suffixRange != nil {
                    let range: NSRange = NSMakeRange(prefixRange!.location + prefixRange!.length, suffixRange!.location - prefixRange!.location - prefixRange!.length)
                    substring = string!.substring(with: range)
                }
            }
        }
        return substring
    }
}