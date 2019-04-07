//
//  ViewController.swift
//  GeneticImage
//
//  Created by Dzianis Lebedzeu on 12/9/14.
//  Copyright (c) 2014 Home. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var referenceImageView: UIImageView!
    @IBOutlet weak var canvasView: Canvas!
    @IBOutlet weak var hud: UITextView!
    
    var geneticImage = GeneticImage(referenceImage: UIImage(named: "kyle")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canvasView.drawCallback = { view, context, rect in
            if let fittest = self.geneticImage.mostFittest?.dna {
                render(fittest, context: context, rect: rect)
            }
        }
        
        referenceImageView.image = UIImage(named: "kyle")
        
        geneticImage.didBreedNewPopulation = { g in
            let seedTimeFormatted = String(format:"%.3fs", g.seedTime)

            self.hud.text = "Fitenss: \(g.currentFitness)%\n" +
                            "Min fitenss: \(g.lowestFitness)%\n" +
                            "Max fitenss: \(g.highestFitness)%\n" +
                            "Generation time: \(seedTimeFormatted)\n"
            
            self.canvasView.setNeedsDisplay()
        }
        
        geneticImage.run()
    }
}



