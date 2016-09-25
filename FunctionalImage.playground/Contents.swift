//: Playground - noun: a place where people can play

import UIKit
import Tricrho

var str = "Hello, playground"


let i = #imageLiteral(resourceName: "IMG_0919.jpg")

M_PI

let matrix = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2))
let x = NSValue(cgAffineTransform: matrix)


["inputTransform": x] 

//var images: [CIImage] = [i.ciImage!, i.ciImage, i.ciImage]
//let ci = CIImage(image: i)!
//
//let red = extractChannel("red", fromImage: ci)
//let green = extractChannel("green", fromImage: ci)
//let blue = extractChannel("blue", fromImage: ci)
//let combined = recompose(red: red, green: green, blue: blue)
//let rotated = rotate(M_PI / 2)(combined)
//
//
////let i1 = extractChannel("red", fromImage: CIImage(image: i)!)
////let i2 = extractChannel("green", fromImage: CIImage(image: i)!)
////let i3 = extractChannel("blue", fromImage: CIImage(image: i)!)
////blur(30)(CIImage(image: i)!)
//
////rotate(-M_PI / 2)(recompose(red: i1, green: i2, blue: i3))
//
//
//
//
//
//
