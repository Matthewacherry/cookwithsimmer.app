import Foundation
import Capacitor
import Vision
import UIKit

/// On-device OCR for cart screenshots using Apple's Vision framework.
/// Takes a base64 image, returns recognized text reconstructed into lines
/// (top-to-bottom, left-to-right) so the web layer's cart parser can read it
/// like pasted text. No network involved — recognition runs entirely on device.
@objc(TextRecognizerPlugin)
public class TextRecognizerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "TextRecognizerPlugin"
    public let jsName = "TextRecognizer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "recognize", returnType: CAPPluginReturnPromise)
    ]

    @objc func recognize(_ call: CAPPluginCall) {
        guard let b64 = call.getString("image"),
              let data = Data(base64Encoded: b64),
              let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            call.reject("Could not decode image")
            return
        }

        let request = VNRecognizeTextRequest { req, error in
            if let error = error {
                call.reject("Recognition failed: \(error.localizedDescription)")
                return
            }
            let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
            struct Fragment { let midY: CGFloat; let minX: CGFloat; let height: CGFloat; let text: String }
            var fragments: [Fragment] = []
            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let box = obs.boundingBox // normalized, origin bottom-left
                fragments.append(Fragment(midY: box.midY, minX: box.minX, height: box.height, text: candidate.string))
            }
            // Top of image first (higher normalized Y = higher on screen)
            fragments.sort { $0.midY > $1.midY }

            // Group fragments that sit on the same visual row, then order each
            // row left-to-right, so "Item name   $7.79" stays on one line.
            // Store-app cart rows put the product PHOTO on the left and the
            // listing text on the right; Vision also reads text printed on the
            // packaging in the photo. When a row has substantial right-column
            // text, drop its left-column fragments (package-art junk) — but
            // keep rows like quantity steppers whose only real text is left.
            let stepperChars = CharacterSet(charactersIn: "0123456789+-\u{2013}\u{2014}. lboz")
            func flush(_ row: [Fragment]) -> String {
                let sorted = row.sorted { $0.minX < $1.minX }
                let rightFrags = sorted.filter { $0.minX >= 0.38 }
                let rightText = rightFrags.map { $0.text }.joined(separator: "  ")
                if rightText.count >= 10 {
                    return rightText
                }
                if rightFrags.isEmpty {
                    // Row lives entirely in the product-photo column: keep it only
                    // if it reads like a quantity stepper ("- 2 +", "0.25 lb +"),
                    // otherwise it's text printed on the packaging image.
                    let joined = sorted.map { $0.text }.joined(separator: "  ")
                    let lower = joined.lowercased()
                    let looksLikeStepper = lower.count <= 14 &&
                        lower.rangeOfCharacter(from: .decimalDigits) != nil &&
                        lower.unicodeScalars.allSatisfy { stepperChars.contains($0) }
                    return looksLikeStepper ? joined : ""
                }
                return sorted.map { $0.text }.joined(separator: "  ")
            }
            var lines: [String] = []
            var row: [Fragment] = []
            var rowY: CGFloat = 2.0
            for frag in fragments {
                let threshold = max(frag.height * 0.7, 0.008)
                if row.isEmpty || abs(frag.midY - rowY) <= threshold {
                    if row.isEmpty { rowY = frag.midY }
                    row.append(frag)
                } else {
                    lines.append(flush(row))
                    row = [frag]
                    rowY = frag.midY
                }
            }
            if !row.isEmpty {
                lines.append(flush(row))
            }
            call.resolve(["text": lines.filter { !$0.isEmpty }.joined(separator: "\n")])
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                call.reject("Recognition failed: \(error.localizedDescription)")
            }
        }
    }
}
