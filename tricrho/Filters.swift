
import CoreImage

infix operator >|> : AdditionPrecedence

public func >|> <A, B, C>(lhs: @escaping (A) -> B, rhs: @escaping (B) -> C) -> (A) -> C {
  return { x in rhs(lhs(x)) }
}


public typealias Filter = (CIImage) -> CIImage

public func blur(_ radius: Double) -> Filter {
  return { image in
    let parameters = ["inputRadius": radius, kCIInputImageKey: image] as [String : Any]
    let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: parameters)
    return filter!.outputImage!
  }
}

public func rotate(_ angle: Double) -> Filter {
  return { image in
    
    var tx = CGAffineTransform(translationX: image.extent.height / 2, y: image.extent.width / 2)
    tx = tx.rotated(by: CGFloat(angle))
    tx = tx.translatedBy(x: -image.extent.width / 2, y: -image.extent.height / 2)
    
    let params = ["inputTransform": NSValue(cgAffineTransform: tx), kCIInputImageKey: image]
    let filter = CIFilter(name: "CIAffineTransform", withInputParameters: params)
    return filter!.outputImage!
  }
}

public func clampColor(min: CIVector, max: CIVector) -> Filter {
  return { image in
    let parameters = ["inputMinComponents": min, "inputMaxComponents": max,
      kCIInputImageKey: image]
    let filter = CIFilter(name: "CIColorClamp", withInputParameters: parameters)
    return filter!.outputImage!
  }
}

public func screen(_ background: CIImage) -> Filter {
  return { image in
    let parameters = [kCIInputBackgroundImageKey: background, kCIInputImageKey: image]
    let filter = CIFilter(name: "CIScreenBlendMode", withInputParameters: parameters)
    return filter!.outputImage!
  }
}

public func extractChannel(_ channel: String, fromImage image: CIImage) -> CIImage {
  let min = CIVector(cgRect: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0))
  let masks = [
    "red": CIVector(cgRect: CGRect(x: 1.0, y: 0.0, width: 0.0, height: 1.0)),
    "green": CIVector(cgRect: CGRect(x: 0.0, y: 1.0, width: 0.0, height: 1.0)),
    "blue": CIVector(cgRect: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
  ]
  return clampColor(min: min, max: masks[channel]!)(image)
}

public func recompose(red: CIImage, green: CIImage, blue: CIImage) -> CIImage {
  return (screen(red) >|>  screen(green))(blue)
}


