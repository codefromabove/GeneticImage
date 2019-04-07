//
//  CGImageExtensions.swift
//  GeneticImage
//
//  Created by Dzianis Lebedzeu on 12/19/14.
//  Copyright (c) 2014 Home. All rights reserved.
//

import Foundation
import UIKit

func resizeCGImage(image: CGImage, toSize size: CGSize) -> CGImage
{
    let width = Int(size.width)
    let height = Int(size.height)
    
    let context = CGBitmapContextCreate(nil, width, height,
        CGImageGetBitsPerComponent(image),
        CGImageGetBytesPerRow(image),
        CGImageGetColorSpace(image)!,
        CGImageGetBitmapInfo(image).rawValue)
    
    CGContextDrawImage(context!, CGRectMake(0, 0, size.width, size.height), image);
    let result = CGBitmapContextCreateImage(context!)
    
    return result!
}

func CGImageFromUIView(view: UIView) -> CGImage {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, view.contentScaleFactor)
    let context = UIGraphicsGetCurrentContext()
    view.layer.renderInContext(context!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    return image!.CGImage!
}

func rawDataFromCGImage(image: CGImage) -> UnsafeBufferPointer<CUnsignedChar> {
    
    let width = CGImageGetWidth(image)
    let height = CGImageGetHeight(image)
    
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB();
    let bytesPerPixel:Int = 4
    
    let bytesPerRow: Int = bytesPerPixel * width
    let bitsPerComponent: Int = 8
    
    let size: Int = Int(bytesPerRow * height)
    let rawData = UnsafeMutablePointer<CUnsignedChar>.alloc(size)
    
    let context = CGBitmapContextCreate(rawData,
        width,
        height,
        bitsPerComponent,
        bytesPerRow,
        colorSpace,
        bitmapInfo.rawValue);
    
    CGContextDrawImage(context!, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image);
    
    let buffer = UnsafeBufferPointer(start: rawData, count: size)
    rawData.destroy()
    
    return buffer
}
