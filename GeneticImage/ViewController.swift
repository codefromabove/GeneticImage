//
//  ViewController.swift
//  GeneticImage
//
//  Created by Dzianis Lebedzeu on 12/9/14.
//  Copyright (c) 2014 Home. All rights reserved.
//

import UIKit

/* The working area, used by the fitness function to determine an individuals
* fitness.
*/
var workingData: UnsafeBufferPointer<CUnsignedChar>!

/* Genetics options.
*/
var populationSize: Int = 40
var selectionCutoff: Float = 0.25
var mutationChance: Float = 0.024
var mutateAmount: Float = 0.1
var fittestSurvive: Bool = false
var randomInheritance: Bool = false
var diffSquared: Bool = true

/* Graphics options.
*/
var workingSize: Int = 70
var polygons: Int = 120
var vertices: Int = 6
var fillPolygons: Bool = true

/* Simulation session variables.
*/
var geneSize: Int = 4 + vertices * 2
var dnaLength: Int = polygons * geneSize
var lowestFitness: Float = 100
var highestFitness: Float = 0
var startTime: Int = 0



/**
:returns: random float in range 0...1.0
*/
func _random() -> Float {
    return Float(arc4random_uniform(1000)) / 1000.0
}

struct Individual {
    var dna: [Float]
    var fitness: Float = 0.0
    
    init() {
        dna = []
        for (var g = 0; g < dnaLength; g += geneSize) {
            dna.extend([
                _random(),  // R
                _random(),  // G
                _random(),   // B
                max(_random() * _random(), 0.2) // A
                ])
            
            let x = _random()
            let y = _random()
            
            for (var j = 0; j < vertices; j++) {
                dna.extend([
                    x + _random() - 0.5, //X
                    y + _random() - 0.5 //Y
                    ])
            }
        }
        calcFitness()
    }
    
    init(mother: [Float], father: [Float]) {
        dna = []
        let inheritSplit = Int(_random() * Float(dnaLength))
        
        for (var i = 0; i < dnaLength; i += geneSize) {
            var inheritedGene: [Float]
            if randomInheritance {
                /* Randomly inherit genes from parents in an uneven manner */
                inheritedGene = (i < inheritSplit) ? mother : father
            } else {
                /* Inherit genes evenly from both parents */
                inheritedGene = (_random() < 0.5) ? mother : father
            }
            
            for (var j = 0; j < geneSize; j++) {
                var dna = inheritedGene[i + j]
                
                if _random() < mutationChance {
                    dna += _random() * mutateAmount * 2 - mutateAmount
                    
                    if dna < 0.0 { dna = 0.0 }
                    if dna > 1.0 { dna = 1.0 }
                }
                
                self.dna.append(dna)
            }
        }
        calcFitness()
    }
    
    mutating func calcFitness() {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGFloat(workingSize), CGFloat(workingSize)), true, 1.0)
        let context = UIGraphicsGetCurrentContext()
        draw(context, rect: CGRectMake(0, 0, CGFloat(workingSize), CGFloat(workingSize)))
        let image = CGBitmapContextCreateImage(context)
        UIGraphicsEndImageContext()
        
        //        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        //        let documentDirectory = paths[0] as String
        //        let myFilePath = documentDirectory.stringByAppendingPathComponent("nameOfMyFile")
        //        UIImagePNGRepresentation(UIImage(CGImage:image)).writeToFile(myFilePath, atomically: true)
        //        println(myFilePath)
        //
        let imageData = rawDataFromCGImage(image)
        
        var diff = 0
        var p = workingSize * workingSize * 4 - 1
        //
        for (var i = 0; i < p; i++) {
            if i % 3 == 0 { //ignore alpha
                //  println(imageData[p])
                continue
            }
            var dp: Int = imageData[i] - workingData[i]
            if (diffSquared) {
                diff += dp * dp
            } else {
                diff += abs(dp)
            }
        }
        
        if diffSquared {
            fitness = 1.0 - Float(diff) / Float(workingSize * workingSize * 3 * 256 * 256)
        } else {
            fitness = 1.0 - Float(diff) / Float(workingSize * workingSize * 3 * 256)
        }
    }
    
    func draw(context: CGContext, rect: CGRect) {
        
        let width = Float(rect.width)
        let height = Float(rect.height)
        
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextFillRect(context, rect)
        
        
        for (var g = 0; g < dnaLength; g += geneSize) {
            
            CGContextMoveToPoint(context, CGFloat(dna[g+4] * width), CGFloat(dna[g+5] * height)) //start at this point
            
            for (var i = 0; i < vertices - 1; i++) {
                CGContextAddLineToPoint(context, CGFloat(dna[g + i * 2 + 6] * width), CGFloat(dna[g + i * 2 + 7] * height))
            }
            
            let color = UIColor(red: CGFloat(dna[g]), green: CGFloat(dna[g+1]), blue: CGFloat(dna[g+2]), alpha: CGFloat(dna[g+3]))
            
            if fillPolygons {
                CGContextSetFillColorWithColor(context, color.CGColor)
                CGContextFillPath(context)
            } else {
                CGContextSetLineWidth(context, 1.0);
                CGContextSetStrokeColorWithColor(context, color.CGColor)
                CGContextStrokePath(context)
            }
        }
    }
    
}

func seed(var population: Population) -> Population {
    if population.count > 1 {
        let size = population.count
        var offspring: Population = [] //TODO: prepopulate with values
        
        /* The number of individuals from the current generation to select for
        * breeding
        */
        let selectCount = Int(floorf(Float(size) * selectionCutoff))
        
        /* The number of individuals to randomly generate */
        var randCount = Int(ceil(1.0 / selectionCutoff))
        
        population = population.sorted { $0.fitness > $1.fitness }
        
        if fittestSurvive {
            randCount-=1
        }
        
        for (var i = 0; i < selectCount; i++) {
            for (var j = 0; j < randCount; j++) {
                var randIndividual = i
                
                while randIndividual == i {
                    randIndividual = Int(_random() * Float(selectCount))
                }
                let ind = Individual(mother: population[i].dna, father: population[randIndividual].dna)
                offspring.append(ind)
            }
        }
        if fittestSurvive {
            population = Array(population[0..<selectCount])
            population.extend(offspring)
        } else {
            population = offspring
        }
        population = Array(population[0..<size])
    } else {
        /*
        * Asexual reproduction:
        */
        let parent = population.first!
        let child = Individual(mother: parent.dna, father: parent.dna)
        
        if (child.fitness > parent.fitness) {
            population = [child]
        }
    }
    return population
}


/**
:param: individuals: collection of individuals

:returns: Individual with highest fitness
*/

func fittest(individuals: [Individual]) -> Individual {
    return individuals.reduce(individuals[0]) { $0.fitness > $1.fitness ? $0 : $1 }
}

func prepareImage() {
    let image = UIImage(named: "kyle")!
    // TODO: resize preserving aspect
    let resized = resizeCGImage(image.CGImage, toSize: CGSizeMake(CGFloat(workingSize), CGFloat(workingSize)))
    workingData = rawDataFromCGImage(resized)
}

class Canvas: UIView {
    
    var ind: Individual?
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        // ind?.draw(context, rect: rect)
        ind?.draw(context, rect: CGRectMake(0, 0, CGFloat(350), CGFloat(350)))
    }
}


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

typealias Population = [Individual]

class ViewController: UIViewController {
    
    var population: Population!
    override func loadView() {
        view = Canvas()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareImage()
        population = (0..<populationSize).map { _ in Individual() }
        
        let link  = CADisplayLink(target: self, selector: "tick")
        link.frameInterval = 3;//20fps 60/n = fps
        link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func tick() {
        population = seed(population)
        let mostFittest = fittest(population)
        
        var currentFitness = mostFittest.fitness * 100.0
        lowestFitness = min(currentFitness, lowestFitness)
        highestFitness = max(currentFitness, highestFitness)
        
        
        let canvas = view as Canvas
        println(mostFittest.fitness)
        canvas.ind = mostFittest
        canvas.setNeedsDisplay()
    }
}

