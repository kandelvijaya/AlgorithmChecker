//
//  Randomizable.swift
//  AlgoChecker
//
//  Created by Vijaya Prakash Kandel on 21.10.18.
//

import Foundation

/// Provide a way to generate random elements in evey single call.
public protocol Randomizabel {
    static var random: Self { get }
}


public func random<T>() -> T where T: Randomizabel{
    return T.random
}


extension Int: Randomizabel {
    /// how would one reduce with + to another Int if the random range is from
    /// Int.min to Int.max
    public static var random: Int =  Int.random(in: -1000..<1000)
}


extension Array where Element: Randomizabel {
    public var random: Array<Element> {
        get {
            return self.map { _ in Element.random }
        }
    }
}
