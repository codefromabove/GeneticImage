//
//  GeneticImage.swift
//  GeneticImage
//
//  Created by Dzianis Lebedzeu on 12/19/14.
//  Copyright (c) 2014 Home. All rights reserved.
//

import Foundation
import UIKit

/* The working area, used by the fitness function to determine an individuals
* fitness.
*/
var workingData: UnsafeBufferPointer<CUnsignedChar>!

/* Genetics options.
*/
var selectionCutoff: Float = 0.25
var mutationChance: Float = 0.024
var mutateAmount: Float = 0.1
var randomInheritance: Bool = false
var diffSquared: Bool = true

/* Graphics options.
*/
var workingSize: CGFloat = 70.0
var polygons: Int = 120
var vertices: Int = 3
var fillPolygons: Bool = true

/**
:returns: random float in range 0...1.0
*/
func _random() -> Float {
    let r : CGFloat = _random()
    return Float(r)
}

func _random() -> CGFloat {
    if NSClassFromString("XCTestCase") == nil {
        return CGFloat(arc4random_uniform(1000)) / 1000.0
    } else {
        return 1
    }
}

func toDictionary<E, K, V>(
    array:       [E],
    transform: (element: E) -> (key: K, value: V)?)
    -> Dictionary<K, V>
{
    return array.reduce([:]) {
        (var dict, e) in
        if let (key, value) = transform(element: e) {
            dict[key] = value
        }
        return dict
    }
}

typealias Point = (x: CGFloat, y: CGFloat)
typealias Color = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
typealias Polygon = [Point]
public typealias Population = [Individual]
typealias DNA = [Nucleotide]

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
        return Nucleotide(color: randomColor(), polygon: randomPolygon(vertices))
    }
    
    private static func randomColor() -> Color {
        return (_random(), _random(), _random(), max(_random() * _random(), 0.2))
    }
    
    private static func randomPolygon(vertices: Int) -> Polygon {
        let base: Point = (_random(), _random())
        return (0..<vertices).map { _ in (base.x + _random() - 0.5, base.y + _random() - 0.5) }
    }
}


public struct Individual {
    var dna: DNA
    var fitness: Float = 0.0
    
    init(dnaLength: Int) {
        dna = (0..<dnaLength).map { _ in Nucleotide.random() }
        calcFitness()
    }
    
    init(mother: Individual, father: Individual, mutationProbability: Float, randomInheritance: Bool) {
        let length = mother.dna.count
        dna = Array(count: length, repeatedValue: mother.dna[0])
        
        let inheritSplit = Int(_random() * Float(length))
        
        //TODO: unsafe stuff with unsafebuffer
        
        for var i = 0; i < length; i++ {
            var inheritedGene: [Nucleotide]
            if randomInheritance {
                /* Randomly inherit genes from parents in an uneven manner */
                inheritedGene = (i < inheritSplit) ? mother.dna : father.dna
            } else {
                /* Inherit genes evenly from both parents */
                inheritedGene = (_random() < Float(0.5)) ? mother.dna : father.dna
            }
            if mutationProbability > _random() {
                dna[i] = inheritedGene[i].mutate(mutateAmount)
            } else {
                dna[i] = inheritedGene[i]
            }
        }
        calcFitness()
    }
    
    mutating func calcFitness() {
        fitness = relativeFitness(dna, workingData)
    }
}

func relativeFitness(dna: DNA, reference: UnsafeBufferPointer<CUnsignedChar>) -> Float {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(workingSize, workingSize), true, 1.0)
    let context = UIGraphicsGetCurrentContext()
    render(dna, context, CGRectMake(0, 0, workingSize, workingSize))
    let image = CGBitmapContextCreateImage(context)
    UIGraphicsEndImageContext()
    let imageData = rawDataFromCGImage(image)
    
    var diff = 0
    
    for var i = 0; i < imageData.count; i++ {
        if i % 3 == 0 { //ignore alpha
            continue
        }
        let dp: Int = imageData[i] - reference[i]
        if (diffSquared) {
            diff += dp * dp
        } else {
            diff += abs(dp)
        }
    }
    
    if diffSquared {
        return 1.0 - Float(diff) / Float(workingSize * workingSize * 3 * 256 * 256)
    } else {
        return 1.0 - Float(diff) / Float(workingSize * workingSize * 3 * 256)
    }
}

func render(dna: DNA, context: CGContext, rect: CGRect) {
    let width = rect.width
    let height = rect.height
    
    CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
    CGContextFillRect(context, rect)
    
    for nucleotide in dna {
        let polygon = nucleotide.polygon
        let color = nucleotide.color
        let start = polygon[0]
        
        CGContextMoveToPoint(context, CGFloat(start.x * width), CGFloat(start.y * height))
        
        for (x, y) in polygon {
            CGContextAddLineToPoint(context, x * width, y * height)
        }
        
        let drawColor = UIColor(red: color.r, green: color.g, blue: color.b, alpha: color.a).CGColor
        
        if fillPolygons {
            CGContextSetFillColorWithColor(context, drawColor)
            CGContextFillPath(context)
        } else {
            CGContextSetLineWidth(context, 1.0);
            CGContextSetStrokeColorWithColor(context, drawColor)
            CGContextStrokePath(context)
        }
    }
}

public func seed(var population: Population, fittestSurvive: Bool) -> Population {
    if population.count > 1 {
        let size = population.count
        var offspring: Population = [] //TODO: prepopulate with values
        
        /* The number of individuals from the current generation to select for
        * breeding
        */
        let selectCount = Int(floorf(Float(size) * selectionCutoff))
        
        /* The number of individuals to randomly generate */
        var randomCount = Int(ceil(1.0 / selectionCutoff))
        
        
        population.sort { $0.fitness > $1.fitness }
        
        if fittestSurvive {
            randomCount -= 1
        }
        
        for var i = 0; i < selectCount; i++ {
            for var j = 0; j < randomCount; j++ {
                var randIndividual = i
                
                while randIndividual == i {
                    randIndividual = Int(_random() * Float(selectCount))
                }
                let ind = Individual(mother: population[i], father: population[randIndividual], mutationProbability: mutationChance, randomInheritance: randomInheritance)
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
        let parent = population[0]
        let child = Individual(mother: parent, father: parent, mutationProbability: mutationChance, randomInheritance: randomInheritance)
        
        if (child.fitness > parent.fitness) {
            population = [child]
        }
        return population
    }
}

func fittest(population: Population) -> Individual {
    return population.reduce(population[0]) { $0.fitness > $1.fitness ? $0 : $1 }
}

class Canvas: UIView {
    var drawCallback: ((view: UIView, context:CGContextRef, rect: CGRect) -> ())? = nil
    
    override func drawRect(rect: CGRect) {
        drawCallback?(view: self, context: UIGraphicsGetCurrentContext(), rect: rect)
    }
}

public class GeneticImage: NSObject {
    
    var populationSize: Int = 40
    var fittestSurvive: Bool = false

    public var didBreedNewPopulation: ((geneticImage: GeneticImage) -> ())? = nil
    
    var population: Population
    var seedTime: NSTimeInterval = 0.0
    var mostFittest: Individual? = nil
    var lowestFitness: Float = 100.0
    var highestFitness: Float = 0.0
    var currentFitness: Float = 0.0
    
    
    public init(referenceImage: UIImage) {
        // TODO: resize preserving aspect
        let resized = resizeCGImage(referenceImage.CGImage, toSize: CGSizeMake(workingSize, workingSize))
        workingData = rawDataFromCGImage(resized)
        
        population = (0..<populationSize).map { _ in Individual(dnaLength: polygons) }
    }
    
    public func run() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            while true {
                self.tick()
            }
        }
    }
    
    public func tick() {
        self.seedTime = sampleExecutionTime { () -> () in
            self.population = seed(self.population, self.fittestSurvive)
        }
        
        self.mostFittest = fittest(self.population)
        
        self.currentFitness = self.mostFittest!.fitness * 100.0
        self.lowestFitness = min(self.currentFitness, self.lowestFitness)
        self.highestFitness = max(self.currentFitness, self.highestFitness)
        
        dispatch_async(dispatch_get_main_queue()) { _ in
            self.didBreedNewPopulation?(geneticImage: self)
            return ()
        }
    }
}

func sampleExecutionTime(operation:() -> ()) -> NSTimeInterval {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    return timeElapsed
}
