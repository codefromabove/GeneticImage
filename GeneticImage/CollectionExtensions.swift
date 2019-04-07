//
//  CollectionExtensions.swift
//  GeneticImage
//
//  Created by Dzianis Lebedzeu on 12/19/14.
//  Copyright (c) 2014 Home. All rights reserved.
//

import Foundation

extension Array {
    func concurrentMap<U>(chunks: Int, transform: (Element) -> U, callback: (AnySequence<U>) -> ()) {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let group = dispatch_group_create()
        
        // populate the array
        let r = transform(self[0] as Element)
        var results = Array<U>(count: self.count, repeatedValue:r)
        
        results.withUnsafeMutableBufferPointer {
            ( buffer: inout UnsafeMutableBufferPointer<U>) -> () in
            
            for startIndex in stride(from: 1, to: self.count, by: chunks) {
                dispatch_group_async(group, queue) {
                    let endIndex = min(startIndex + chunks, self.count)
                    let chunkedRange = self[startIndex..<endIndex]
                    
                    for (index, item) in enumerate(chunkedRange) {
                        buffer[index + startIndex] = transform(item)
                    }
                }
            }
            
            dispatch_group_notify(group, queue) {
                callback(AnySequence(buffer))
            }
        }
    }
}
