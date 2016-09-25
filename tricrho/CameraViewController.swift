import UIKit

import AVFoundation
import AVKit
import GLKit

import ObjectiveC

typealias BlockButtonActionBlock = (_ sender: UIButton) -> Void

class ButtonCreator : NSObject {
  let button: UIButton

  init(withLabel label: String) {
    button = UIButton(type: .system)
    button.setTitle(label, for: UIControlState())
    button.tintColor = UIColor.red
    button.backgroundColor = UIColor.white
    button.layer.cornerRadius = 5.0
    
    super.init()
  }
  
  func frame(_ frame: CGRect) -> ButtonCreator {
    button.frame = frame
    return self
  }
}

var ActionBlockKey: UInt8 = 0

// a type for our action block closure


class ActionBlockWrapper : NSObject {
  var block : BlockButtonActionBlock
  init(block: @escaping BlockButtonActionBlock) {
    self.block = block
  }
}

extension UIButton {
  func onTouchUpInside(_ closure: @escaping BlockButtonActionBlock) {
    objc_setAssociatedObject(self, &ActionBlockKey, ActionBlockWrapper(block: closure), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    addTarget(self, action: #selector(UIButton.block_handleAction(_:)), for: .touchUpInside)
  }
  
  func block_handleAction(_ sender: UIButton) {
    let wrapper = objc_getAssociatedObject(self, &ActionBlockKey) as! ActionBlockWrapper
    wrapper.block(sender)
  }
}


class LayerFitView : UIView {
  var sizeableLayer = CALayer()
  
  func addSizedLayer(_ layer: CALayer) {
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
    self.init(cvPixelBuffer: CMSampleBufferGetImageBuffer(buffer)!)
  }
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

  var session = AVCaptureSession()
  var previewLayer = AVCaptureVideoPreviewLayer()
  var skipped = 0
  var snapping = false
  var images = [CIImage]()
  
  func getOrientation(_ orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation{
    switch(orientation){
    case .landscapeLeft:
      print("Left");
      return .landscapeLeft
    case .landscapeRight:
      return .landscapeRight
    default:
      print("¯\\_(ツ)_/¯")
      return .portrait
    }
  }
  
  override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
    print("will Rotate suckaz")
    previewLayer.frame = self.view.bounds
    print(UIDevice.current.orientation)
    let connection:AVCaptureConnection  = previewLayer.connection
    connection.videoOrientation = .portrait

  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    var backCameraDevice: AVCaptureDevice?
    
    let devicesTypes: [AVCaptureDeviceType] = [.builtInDuoCamera, .builtInWideAngleCamera]
    let availableCameraDevices = AVCaptureDeviceDiscoverySession(deviceTypes: devicesTypes, mediaType: nil, position: .back)
    
    for device in availableCameraDevices!.devices {
      print("found device", device)
      backCameraDevice = device
    }
    
    if let bcd = backCameraDevice {
      do {
        let possibleCameraInput = try AVCaptureDeviceInput(device: bcd)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
        
        
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
            .frame(CGRect(x: (self.view.bounds.width / 2) - 34, y: self.view.bounds.height - 88, width: 68, height: 68)).button
          
          button.setImage(UIImage(named: "snap"), for: UIControlState())
          button.backgroundColor = UIColor.clear
          button.tintColor = UIColor.white
          button.onTouchUpInside { sender in
            self.snapping = true
          }
          
          self.view.addSubview(button)
          self.view.bringSubview(toFront: button)
          
          print("camera time bitches")
        }
        
        
      } catch let error as NSError {
        // Handle any errors
        print(error)
      }

    }
  }
  
  func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
    if error == nil {
      let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
      ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      present(ac, animated: true, completion: nil)
    } else {
      let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .alert)
      ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      present(ac, animated: true, completion: nil)
    }
  }
  
  func showPreview(_ image: CIImage) {
    let img = UIImage(ciImage: image)
    let imgView = UIImageView(image: img)
    
    imgView.contentMode = .scaleAspectFit
    imgView.frame = self.view.bounds
    
    self.view.addSubview(imgView)
    
    let cancelButton = ButtonCreator(withLabel: "Close")
      .frame(CGRect(x: self.view.bounds.width - 130, y: self.view.bounds.height - 80, width: 100, height: 50)).button
    
    let saveButton = ButtonCreator(withLabel: "Save")
      .frame(CGRect(x: 30, y: self.view.bounds.height - 80, width: 100, height: 50)).button
    
    cancelButton.onTouchUpInside { sender in
      print("closing")
      imgView.removeFromSuperview()
      cancelButton.removeFromSuperview()
      saveButton.removeFromSuperview()
      self.session.startRunning()
    }

    self.view.addSubview(cancelButton)

    
    saveButton.onTouchUpInside { sender in
      print("savign")
      let imageContext = CIContext(options:nil)
      let img = imageContext.createCGImage(image, from: image.extent)
      UIImageWriteToSavedPhotosAlbum(UIImage(cgImage: img!), self, #selector(CameraViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
      imgView.removeFromSuperview()
      cancelButton.removeFromSuperview()
      saveButton.removeFromSuperview()
      self.session.startRunning()
    }
    
    self.view.addSubview(saveButton)

    print("show!!!")
    
  }
  
  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                    from connection: AVCaptureConnection!) {
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
          DispatchQueue.main.async { [unowned self] in
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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print("MEMORY")
    // Dispose of any resources that can be recreated.
  }


}

