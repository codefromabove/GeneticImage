//
//  GeneticImageTests.swift
//  GeneticImageTests
//
//  Created by Dzianis Lebedzeu on 12/9/14.
//  Copyright (c) 2014 Home. All rights reserved.
//

import UIKit
import XCTest
import GeneticImage

class GeneticImageTests: XCTestCase {
    
    var genetic: GeneticImage!
    
    override func setUp() {
        super.setUp()
        genetic = GeneticImage(referenceImage: UIImage(named: "kyle")!)
    }
    
    func testTickPerformance() {
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) { () -> Void in
            let readyExpectation = self.expectationWithDescription("ready")
            self.genetic.didBreedNewPopulation = { _ in
                readyExpectation.fulfill()
            }
            self.startMeasuring()
            
            self.genetic.tick()
            
            self.waitForExpectationsWithTimeout(1, handler: { error in
                self.stopMeasuring()
            })
        }
    }
}
