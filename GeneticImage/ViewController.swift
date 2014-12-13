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
var workingSize: CGFloat = 70.0
var polygons: Int = 120
var vertices: Int = 6
var fillPolygons: Bool = true

/* Simulation session variables.
*/
var lowestFitness: Float = 100
var highestFitness: Float = 0

/**
:returns: random float in range 0...1.0
*/
func _random() -> Float {
    return Float(arc4random_uniform(1000)) / 1000.0
}

func _random() -> CGFloat {
    return CGFloat(arc4random_uniform(1000)) / 1000.0
}

typealias Point = (x: CGFloat, y: CGFloat)
typealias Color = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
typealias Polygon = [Point]

typealias Population = [Individual]

struct Nucleotide {
    let color: Color
    let polygon: Polygon

}

// Mutation
extension Nucleotide {
    func mutate(amount: Float) -> Nucleotide {
        return Nucleotide(color: mutateColor(color, amount), polygon: mutatePolygon(polygon, amount))
    }
    
    private func mutateColor(color: Color, _ amount: Float) -> Color {
        return (mutateValue(amount, color.r), mutateValue(amount, color.g), mutateValue(amount, color.b), mutateValue(amount, color.a))
    }
    
    private func mutatePolygon(polygon: Polygon, _ amount: Float) -> Polygon {
        let mutatePoint: (p: Point) -> Point = { p in (self.mutateValue(amount, p.x) , self.mutateValue(amount, p.y)) }
        return polygon.map(mutatePoint)
    }
    
    func mutateValue(amount: Float, _ value: CGFloat) -> CGFloat {
        var result = value + _random() * CGFloat(amount) * 2.0 - CGFloat(amount)
        if result < 0.0 { result = 0.0 }
        if result > 1.0 { result = 1.0 }
        return result
    }
}

// Random
extension Nucleotide {
    static func random() -> Nucleotide {
        return Nucleotide(color: randomColor(), polygon: randomPolygon(polygons))
    }
    
    private static func randomColor() -> Color {
        return (_random(), _random(), _random(), max(_random() * _random(), 0.2))
    }
    
    private static func randomPolygon(vertices: Int) -> Polygon {
        let base: Point = (_random(), _random())
        return (0..<vertices).map { _ in (base.x + _random() - 0.5, base.y + _random() - 0.5) }
    }
}


struct Individual {
    var dna: [Nucleotide]
    var fitness: Float = 0.0
    
    init() {
        dna = (0..<polygons).map { _ in Nucleotide.random() }
        calcFitness()
    }
    
    init(mother: Individual, father: Individual) {
        dna = Array(count: polygons, repeatedValue: mother.dna[0])
        
        let inheritSplit = Int(_random() * Float(polygons))
        
        //TODO: unsafe stuff with unsafebuffer
        
        for var i = 0; i < polygons; i++ {
            var inheritedGene: [Nucleotide]
            if randomInheritance {
                /* Randomly inherit genes from parents in an uneven manner */
                inheritedGene = (i < inheritSplit) ? mother.dna : father.dna
            } else {
                /* Inherit genes evenly from both parents */
                inheritedGene = (_random() < Float(0.5)) ? mother.dna : father.dna
            }
            
            var d = inheritedGene[i]
            
            if mutationChance > _random() {
                dna[i] = d.mutate(mutateAmount)
            } else {
                dna[i] = d
            }
        }
        calcFitness()
    }
    
    mutating func calcFitness() {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(workingSize, workingSize), true, 1.0)
        let context = UIGraphicsGetCurrentContext()
        draw(context, rect: CGRectMake(0, 0, workingSize, workingSize))
        let image = CGBitmapContextCreateImage(context)
        UIGraphicsEndImageContext()
        let imageData = rawDataFromCGImage(image)
        
        var diff = 0
        var p = Int(workingSize * workingSize * 4 - 1)
    
        for var i = 0; i < p; i++ {
            if i % 3 == 0 { //ignore alpha
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
        
        let width = rect.width
        let height = rect.height
        
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextFillRect(context, rect)
        
        
        for var g = 0; g < polygons; g++ {
            let nucleotide = dna[g]
            let start = nucleotide.polygon[0]
            
            CGContextMoveToPoint(context, CGFloat(start.x * width), CGFloat(start.y * height))
            
            for (var i = 1; i < vertices; i++) {
                let (x, y) = nucleotide.polygon[i]
                CGContextAddLineToPoint(context, x * width, y * height)
            }
    
            let color = UIColor(red: nucleotide.color.r, green: nucleotide.color.g, blue: nucleotide.color.b, alpha: nucleotide.color.a)
            
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
        
        population.sort { $0.fitness > $1.fitness }
        
        if fittestSurvive {
            randCount -= 1
        }
        
        for var i = 0; i < selectCount; i++ {
            for var j = 0; j < randCount; j++ {
                var randIndividual = i
                
                while randIndividual == i {
                    randIndividual = Int(_random() * Float(selectCount))
                }
                let ind = Individual(mother: population[i], father: population[randIndividual])
                offspring.append(ind)
            }
        }
        if fittestSurvive {
            population = Array(population[0..<selectCount])
            population.extend(offspring)
            population = Array(population[0..<size])
            return population
        } else {
            return offspring
        }
    } else {
        // Asexual reproduction
        let parent = population.first!
        let child = Individual(mother: parent, father: parent)
        
        if (child.fitness > parent.fitness) {
            population = [child]
        }
        return population
    }
}

func fittest(population: Population) -> Individual {
    return population.reduce(population[0]) { $0.fitness > $1.fitness ? $0 : $1 }
}

func prepareImage() {
    let image = UIImage(named: "kyle")!
    // TODO: resize preserving aspect
    let resized = resizeCGImage(image.CGImage, toSize: CGSizeMake(workingSize, workingSize))
    workingData = rawDataFromCGImage(resized)
}

class Canvas: UIView {
    
    var ind: Individual?
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        ind?.draw(context, rect: rect)
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

class ViewController: UIViewController {
    
    @IBOutlet weak var referenceImageView: UIImageView!
    @IBOutlet weak var canvasView: Canvas!
    @IBOutlet weak var hud: UITextView!
    
    var population: Population!

    override func viewDidLoad() {
        super.viewDidLoad()
        referenceImageView.image = UIImage(named: "kyle")
        
        prepareImage()
        population = (0..<populationSize).map { _ in Individual() }
        
        let link = CADisplayLink(target: self, selector: "tick")
        link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func tick() {
        
        let seedTime = sampleExecutionTime { () -> () in
            self.population = seed(self.population)
        }
        
        let mostFittest = fittest(population)
        
        var currentFitness = mostFittest.fitness * 100.0
        lowestFitness = min(currentFitness, lowestFitness)
        highestFitness = max(currentFitness, highestFitness)
        
        let seedTimeFormatted = String(format:"%.3fs", seedTime)
        
        hud.text =  "Fitenss: \(currentFitness)%\n" +
                    "Min fitenss: \(lowestFitness)%\n" +
                    "Max fitenss: \(highestFitness)%\n" +
                    "Generation time: \(seedTimeFormatted)\n"
        
        canvasView.ind = mostFittest
        canvasView.setNeedsDisplay()
    }
}

func sampleExecutionTime(operation:() -> ()) -> NSTimeInterval {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    return timeElapsed
}

