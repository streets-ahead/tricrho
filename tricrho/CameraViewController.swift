import UIKit

import AVFoundation
import AVKit
import GLKit

import ObjectiveC

typealias BlockButtonActionBlock = (sender: UIButton) -> Void

class ButtonCreator : NSObject {
  let button: UIButton

  init(withLabel label: String) {
    button = UIButton(type: .System)
    button.setTitle(label, forState: .Normal)
    button.tintColor = UIColor.redColor()
    button.backgroundColor = UIColor.whiteColor()
    button.layer.cornerRadius = 5.0
    
    super.init()
  }
  
  func frame(frame: CGRect) -> ButtonCreator {
    button.frame = frame
    return self
  }
}

var ActionBlockKey: UInt8 = 0

// a type for our action block closure


class ActionBlockWrapper : NSObject {
  var block : BlockButtonActionBlock
  init(block: BlockButtonActionBlock) {
    self.block = block
  }
}

extension UIButton {
  func onTouchUpInside(closure: BlockButtonActionBlock) {
    objc_setAssociatedObject(self, &ActionBlockKey, ActionBlockWrapper(block: closure), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    addTarget(self, action: "block_handleAction:", forControlEvents: .TouchUpInside)
  }
  
  func block_handleAction(sender: UIButton) {
    let wrapper = objc_getAssociatedObject(self, &ActionBlockKey) as! ActionBlockWrapper
    wrapper.block(sender: sender)
  }
}


class LayerFitView : UIView {
  var sizeableLayer = CALayer()
  
  func addSizedLayer(layer: CALayer) {
    self.layer.frame = self.bounds
    self.layer.addSublayer(layer)
    self.sizeableLayer = layer
  }
  
  override func layoutSubviews() {
    self.sizeableLayer.frame = self.bounds
  }
}

extension CIImage {
  convenience init(buffer: CMSampleBuffer) {
    self.init(CVPixelBuffer: CMSampleBufferGetImageBuffer(buffer)!)
  }
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

  let session: AVCaptureSession = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  var skipped = 0
  var snapping = false
  var images = [CIImage]()
  
  func getOrientation(orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation{
    switch(orientation){
    case .LandscapeLeft:
      print("Left");
      return AVCaptureVideoOrientation.LandscapeRight
    case .LandscapeRight:
      return AVCaptureVideoOrientation.LandscapeLeft
    default:
      print("¯\\_(ツ)_/¯")
      return AVCaptureVideoOrientation.Portrait
    }
  }
  
  override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
    print("did Rotate suckaz")
    previewLayer.frame = self.view.bounds
    print(UIDevice.currentDevice().orientation)
    let connection:AVCaptureConnection  = previewLayer.connection
    let deviceOrientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
    connection.videoOrientation = self.getOrientation(deviceOrientation)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    print("hellow2")
    
    
    var backCameraDevice: AVCaptureDevice?
    
    let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
    
    for device in availableCameraDevices as! [AVCaptureDevice] {
      if device.position == .Back {
        print("back")
        backCameraDevice = device
        break
      }
    }
    
    if let bcd = backCameraDevice {
      do {
        let possibleCameraInput = try AVCaptureDeviceInput(device: bcd)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        
        if session.canAddInput(possibleCameraInput) {
          print("adding")
          session.addInput(possibleCameraInput)
          
          session.addOutput(videoOutput)
          
          previewLayer = AVCaptureVideoPreviewLayer(session: session)
          
          let v: LayerFitView = self.view as! LayerFitView
          v.addSizedLayer(previewLayer)

          session.startRunning()
          
          print("camera time bitches")
          
          let button = ButtonCreator(withLabel: "")
            .frame(CGRectMake((self.view.bounds.width / 2) - 34, self.view.bounds.height - 88, 68, 68)).button
          
          button.setImage(UIImage(named: "snap"), forState: .Normal)
          button.backgroundColor = UIColor.clearColor()
          button.tintColor = UIColor.whiteColor()
          button.onTouchUpInside { sender in
            self.snapping = true
          }
          
          self.view.addSubview(button)
          self.view.bringSubviewToFront(button)
          
          print("camera time bitches")
        }
        
        
      } catch let error as NSError {
        // Handle any errors
        print(error)
      }

    }
  }
  
  func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
    if error == nil {
      let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .Alert)
      ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
      presentViewController(ac, animated: true, completion: nil)
    } else {
      let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .Alert)
      ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
      presentViewController(ac, animated: true, completion: nil)
    }
  }
  
  func showPreview(image: CIImage) {
    let img = UIImage(CIImage: image, scale: 1, orientation: UIImageOrientation.Up)
    let imgView = UIImageView(image: img)
    imgView.contentMode = .ScaleAspectFit
    imgView.frame = self.view.frame
    self.view.addSubview(imgView)
    
    let button = ButtonCreator(withLabel: "Close")
      .frame(CGRectMake(self.view.bounds.width - 130, self.view.bounds.height - 80, 100, 50)).button
    
    let saveButton = ButtonCreator(withLabel: "Save")
      .frame(CGRectMake(30, self.view.bounds.height - 80, 100, 50)).button
    
    button.onTouchUpInside { sender in
      print("closing")
      imgView.removeFromSuperview()
      button.removeFromSuperview()
      saveButton.removeFromSuperview()
      self.session.startRunning()
    }

    self.view.addSubview(button)

    
    
    
    saveButton.onTouchUpInside { sender in
      print("savign")
      let imageContext = CIContext(options:nil)
      let i = imageContext.createCGImage(image, fromRect: image.extent)
      UIImageWriteToSavedPhotosAlbum(UIImage(CGImage: i), self, "image:didFinishSavingWithError:contextInfo:", nil)
      imgView.removeFromSuperview()
      button.removeFromSuperview()
      saveButton.removeFromSuperview()
      self.session.startRunning()
    }
    
    self.view.addSubview(saveButton)

    print("show!!!")
    
  }
  
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                    fromConnection connection: AVCaptureConnection!) {
    if snapping {
      skipped = skipped + 1
      switch skipped {
        case 1, 10, 20:
          let image = CIImage(buffer: sampleBuffer)
          print("found image")
          print(image)
          images.append(image)
        case let x where x > 20:
          print("all done")
          self.session.stopRunning()
          let red = extractChannel("red", fromImage: images[0])
          let green = extractChannel("green", fromImage: images[1])
          let blue = extractChannel("blue", fromImage: images[2])
          let combined = recompose(red: red, green: green, blue: blue)
          let rotated = rotate(-M_PI / 2)(combined)
          dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            self.showPreview(rotated)
          }
          images = [CIImage]()
          skipped = 0
          snapping = false
        default:
          print("increment skip")
      }
    }
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print("MEMORY")
    // Dispose of any resources that can be recreated.
  }


}

