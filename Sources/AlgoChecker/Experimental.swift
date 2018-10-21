//
//  Experimental.swift
//  AlgoChecker
//
//  Created by Vijaya Prakash Kandel on 21.10.18.
//

import Foundation

/// TODO:- This is WIP for algorithm that can work asynchronously/dispatch parallel threads
extension AlgorithmChecker {

    struct AlgorithmIdentifier {
        let id: Int
        let size: Int // SampleSize
    }


    /// Intended to use when algorithm can have concurrent/parallel or
    /// do its work on background thread.
    struct _OperationWrapper<U> {
        let storage: Operation<U>
        let identifier: AlgorithmIdentifier
    }

}
