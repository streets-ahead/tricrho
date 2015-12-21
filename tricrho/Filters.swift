
import CoreImage

infix operator >|> { associativity left }

public func >|> <A, B, C>(lhs: A -> B, rhs: B -> C) -> A -> C {
  return { x in rhs(lhs(x)) }
}


public typealias Filter = CIImage -> CIImage

public func blur(radius: Double) -> Filter {
  return { image in
    let parameters = ["inputRadius": radius, kCIInputImageKey: image]
    let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: parameters)
    return filter!.outputImage!
  }
}

public func rotate(angle: Double) -> Filter {
  return { image in
    let matrix = CGAffineTransformMakeRotation(CGFloat(angle))
    return image.imageByApplyingTransform(matrix)
  }
}

public func clampColor(min min: CIVector, max: CIVector) -> Filter {
  return { image in
    let parameters = ["inputMinComponents": min, "inputMaxComponents": max,
      kCIInputImageKey: image]
    let filter = CIFilter(name: "CIColorClamp", withInputParameters: parameters)
    return filter!.outputImage!
  }
}

public func screen(background: CIImage) -> Filter {
  return { image in
    let parameters = [kCIInputBackgroundImageKey: background, kCIInputImageKey: image]
    let filter = CIFilter(name: "CIScreenBlendMode", withInputParameters: parameters)
    return filter!.outputImage!
  }
}

public func extractChannel(channel: String, fromImage image: CIImage) -> CIImage {
  let min = CIVector(CGRect: CGRectMake(0.0, 0.0, 0.0, 0.0))
  let masks = [
    "red": CIVector(CGRect: CGRectMake(1.0, 0.0, 0.0, 1.0)),
    "green": CIVector(CGRect: CGRectMake(0.0, 1.0, 0.0, 1.0)),
    "blue": CIVector(CGRect: CGRectMake(0.0, 0.0, 1.0, 1.0))
  ]
  return clampColor(min: min, max: masks[channel]!)(image)
}

public func recompose(red red: CIImage, green: CIImage, blue: CIImage) -> CIImage {
  return (screen(red) >|>  screen(green))(blue)
}


