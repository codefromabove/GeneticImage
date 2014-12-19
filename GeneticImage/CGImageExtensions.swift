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
    let width = UInt(size.width)
    let height = UInt(size.height)
    
    let context = CGBitmapContextCreate(nil, width, height,
        CGImageGetBitsPerComponent(image),
        CGImageGetBytesPerRow(image),
        CGImageGetColorSpace(image),
        CGImageGetBitmapInfo(image))
    
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
    let result = CGBitmapContextCreateImage(context)
    
    return result
}

func CGImageFromUIView(view: UIView) -> CGImage {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, view.contentScaleFactor)
    let context = UIGraphicsGetCurrentContext()
    view.layer.renderInContext(context)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    return image.CGImage
}

func rawDataFromCGImage(image: CGImage) -> UnsafeBufferPointer<CUnsignedChar> {
    
    let width = CGImageGetWidth(image)
    let height = CGImageGetHeight(image)
    
    let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB();
    let bytesPerPixel:UInt = 4
    
    let bytesPerRow: UInt = bytesPerPixel * width
    let bitsPerComponent: UInt = 8
    
    let size: Int = Int(bytesPerRow * height)
    let rawData = UnsafeMutablePointer<CUnsignedChar>.alloc(size)
    
    let context = CGBitmapContextCreate(rawData,
        width,
        height,
        bitsPerComponent,
        bytesPerRow,
        colorSpace,
        bitmapInfo);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image);
    
    let buffer = UnsafeBufferPointer(start: rawData, count: size)
    rawData.destroy()
    
    return buffer
}