import UIKit
import CoreImage
import GPUImage
import AVFoundation


class ViewController: UIViewController {
    var filterChain = FilterChain()
    
    @IBOutlet var renderView: RenderView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filterChain.start()
        filterChain.startCameraWithView(view: renderView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }


    @IBAction func capture(_ sender: AnyObject) {
        filterChain.capture()
    }
    
    @IBAction func randomizeButton(_ sender: Any) {
        filterChain.randomizeFilterChain()
    }
}

extension ViewController: CameraDelegate {
    func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
        /*
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))!
            let img = CIImage(cvPixelBuffer: pixelBuffer, options: attachments as? [String: AnyObject])
            var lines = [Line]()
            for feature in (faceDetector?.features(in: img, options: [CIDetectorImageOrientation: 6]))! {
                if feature is CIFaceFeature {
                    lines = lines + faceLines(feature.bounds)
                }
            }
            lineGenerator.renderLines(lines)
        }
         */
    }
/*
    func faceLines(_ bounds: CGRect) -> [Line] {
        // convert from CoreImage to GL coords
        
        let flip = CGAffineTransform(scaleX: 1, y: -1)
        let rotate = flip.rotated(by: CGFloat(-M_PI_2))
        let translate = rotate.translatedBy(x: -1, y: -1)
        let xform = translate.scaledBy(x: CGFloat(2/fbSize.width), y: CGFloat(2/fbSize.height))
        let glRect = bounds.applying(xform)

        let x = Float(glRect.origin.x)
        let y = Float(glRect.origin.y)
        let width = Float(glRect.size.width)
        let height = Float(glRect.size.height)

        let tl = Position(x, y)
        let tr = Position(x + width, y)
        let bl = Position(x, y + height)
        let br = Position(x + width, y + height)

        return [.segment(p1:tl, p2:tr),   // top
                .segment(p1:tr, p2:br),   // right
                .segment(p1:br, p2:bl),   // bottom
                .segment(p1:bl, p2:tl)]   // left
    }
 */
}
