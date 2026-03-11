import Flutter
import UIKit
import AVFoundation
import PDFKit

public class FilePreviewerPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "universal_file_previewer",
            binaryMessenger: registrar.messenger()
        )
        let instance = FilePreviewerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            if call.method == "ping" { result(true); return }
            result(FlutterError(code: "ARGS", message: "Invalid arguments", details: nil))
            return
        }

        switch call.method {

        case "ping":
            result(true)

        // ── PDF ──────────────────────────────────────────────────────────
        case "renderPdfPage":
            guard let path = args["path"] as? String,
                  let pageIndex = args["page"] as? Int,
                  let width = args["width"] as? CGFloat else {
                result(FlutterError(code: "ARGS", message: "path, page, width required", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                guard let doc = PDFDocument(url: URL(fileURLWithPath: path)),
                      pageIndex < doc.pageCount,
                      let page = doc.page(at: pageIndex) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "PDF", message: "Cannot open PDF page", details: nil))
                    }
                    return
                }

                let bounds = page.bounds(for: .mediaBox)
                let scale  = width / bounds.width
                let size   = CGSize(width: width, height: bounds.height * scale)

                let renderer = UIGraphicsImageRenderer(size: size)
                let image = renderer.image { ctx in
                    ctx.cgContext.setFillColor(UIColor.white.cgColor)
                    ctx.cgContext.fill(CGRect(origin: .zero, size: size))
                    ctx.cgContext.scaleBy(x: scale, y: scale)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }

                DispatchQueue.main.async {
                    result(image.pngData())
                }
            }

        case "getPdfPageCount":
            guard let path = args["path"] as? String else {
                result(FlutterError(code: "ARGS", message: "path required", details: nil))
                return
            }
            guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
                result(FlutterError(code: "PDF", message: "Cannot open PDF", details: nil))
                return
            }
            result(doc.pageCount)

        // ── Video thumbnail ───────────────────────────────────────────────
        case "generateVideoThumbnail":
            guard let path = args["path"] as? String else {
                result(FlutterError(code: "ARGS", message: "path required", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                let asset     = AVAsset(url: URL(fileURLWithPath: path))
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 1280, height: 720)

                do {
                    let cgImage = try generator.copyCGImage(
                        at: CMTime(seconds: 1, preferredTimescale: 60),
                        actualTime: nil
                    )
                    let image = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        result(image.jpegData(compressionQuality: 0.85))
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "THUMB", message: error.localizedDescription, details: nil))
                    }
                }
            }

        // ── Video info ────────────────────────────────────────────────────
        case "getVideoInfo":
            guard let path = args["path"] as? String else {
                result(FlutterError(code: "ARGS", message: "path required", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                let asset     = AVAsset(url: URL(fileURLWithPath: path))
                let duration  = Int(asset.duration.seconds * 1000)

                var width  = 0
                var height = 0

                if let track = asset.tracks(withMediaType: .video).first {
                    let size = track.naturalSize.applying(track.preferredTransform)
                    width  = Int(abs(size.width))
                    height = Int(abs(size.height))
                }

                DispatchQueue.main.async {
                    result([
                        "duration": duration,
                        "width":    width,
                        "height":   height,
                        "rotation": 0,
                    ])
                }
            }

        // ── HEIC conversion ───────────────────────────────────────────────
        case "convertHeicToJpeg":
            guard let path = args["path"] as? String else {
                result(FlutterError(code: "ARGS", message: "path required", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = UIImage(contentsOfFile: path),
                      let jpegData = image.jpegData(compressionQuality: 0.9) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "HEIC", message: "Cannot convert HEIC", details: nil))
                    }
                    return
                }
                DispatchQueue.main.async {
                    result(jpegData)
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
