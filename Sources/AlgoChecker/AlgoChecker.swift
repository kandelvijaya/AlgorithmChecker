import Foundation
import QuartzCore


/// Provide a way to generate random elements in evey single call.
protocol Randomizabel {
    static var random: Self { get }
}


func random<T>() -> T where T: Randomizabel{
    return T.random
}


extension Int: Randomizabel {
    /// how would one reduce with + to another Int if the random range is from
    /// Int.min to Int.max
    static var random: Int =  Int.random(in: -1000..<1000)
}


extension Array where Element: Randomizabel {
    var random: Array<Element> {
        get {
            return self.map { _ in Element.random }
        }
    }
}


/// Given a algorithm encapsulated in Operation, asserts weather the time
/// complexity of the algorithm matches the expected one.
///
/// This one doesnot parse the code and analyse. However, it runs the algorithm
/// feeding various sized of random input and then analyse the time/size graph
/// with some tolerance to offset system fluctuation.
/// There might be some false positive
struct AlgorithmChecker {

    enum TimeComplexity {
        case linear
        case logarithmic
        case quadratic
        case polynomial
    }

    enum Tolerance {
        /// ±1%
        case none

        /// ±10%
        case low

        /// ±25%
        case medium
    }


    /// Provides sample sizes which can be obtinaed by
    /// `currentSize()` and the size can be incremented if possible
    /// by calling `incrementSize()`. This acts like a UniDirectionalIterator.
    /// When the currentSize cannot be incremented then it terminates with nil.
    ///
    /// Further consideration:
    /// It doesnot make sense to provide same sample size for all algorithms.
    /// Especially if the algorithm is quadratic or polynomial then we can provide
    /// sample size that won't freeze the computer for days. To do such, we can
    /// accumulate result and analyse them and then provide input.
    struct SizeState {

        private var sampleSizes: [Int] {
            return type(of: self).sampleSizes
        }

        private var currentIndex = 0

        mutating func incrementSize() {
            currentIndex += 1
        }

        func currentSize() -> Int? {
            guard currentIndex < sampleSizes.count else { return nil }
            return sampleSizes[currentIndex]
        }

        static var sampleSizes: [Int] {
            return [10, 100, 1000, 10000]
        }

    }


    /// Randomized data source to feed into algorithm input
    /// To get incremental size of randomized inputs, consider calling
    /// `next()` which internally uses a different size based on SizeInput.
    struct InputProvider {

        private var sizeState: SizeState
        let currentSize: Int

        init?(state: SizeState) {
            guard let size = state.currentSize() else {
                return nil
            }
            self.sizeState = state
            self.currentSize = size
        }

        func input<T>() -> T where T: Randomizabel {
            return T.random
        }

        func input<T>() -> T where T: Collection, T.Element: Randomizabel {
            let arr = Array<T.Element>(repeating: T.Element.random, count: currentSize)
            return arr.random as! T
        }

        mutating func next() -> InputProvider? {
            self.sizeState.incrementSize()
            return InputProvider(state: self.sizeState)
        }

    }


    /// Encapsulates the algorithm function.
    /// 1. The algorithm can use provided InputProvider to get the input.
    /// 2. The algorithm must call into the completion block supplied with the result.
    /// 3. `U` is the type of result the algorithm produces.
    struct Operation<U> {
        var fnBlock: (InputProvider, (U) -> Void) -> Void
    }

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


    /// Detects if a provided algorithm has given complexity.
    ///
    /// - Parameters:
    ///   - algorithm: Algorithm wrapped in non-executed Promise
    ///   - complexity: Expected time complexity
    ///   - tolerance: Tolerance on data samples to include (±10% is low, ±20% is medium)
    /// - Returns: Bool
    /// - Throws: Can thorw if the promise was already executed. Can throw if the algorithm doesnot
    ///           support Randomized input.
    mutating func assert<T>(algorithm: Operation<T>, has expectedComplexity: TimeComplexity, tolerance: Tolerance = .none) -> Bool {

        // Storage of the samples collected
        var timeKeeper: [Int: TimeInterval] = [:]

        /// TODO:- InputProvider can be a `Iterator`.
        var ip = InputProvider(state: SizeState())
        while ip != nil {
            let startTime = CACurrentMediaTime()
            algorithm.fnBlock(ip!) { result in
                let stopTime = CACurrentMediaTime()
                timeKeeper[ip!.currentSize] = stopTime - startTime
            }
            ip = ip?.next()
        }

        return analyseComplexity(from: timeKeeper, with: tolerance) == expectedComplexity
    }


    /// Returns time complexity of the algorithm based on sample data and tolerance
    ///
    /// - Parameters:
    ///   - sample: [InputSampleSize: TimeInterval]
    ///   - tolerance: Tolerance to apply such that the system process affect can be negated
    /// - Returns: TimeComplexity
    private mutating func analyseComplexity(from sample: [Int: TimeInterval], with tolerance: Tolerance) -> TimeComplexity {
        let amplifier: Double = 1000
        let tangents = sample.map { ($0.0, ($0.1 * amplifier) / Double($0.0)) }.sorted { $0.0 < $1.0 } // time/size

        Swift.assert(tangents.count > 2, "There are no enough data points to analyse")

        let last = tangents.last!
        let secondLast = tangents.dropLast().last!

        let chekInRange = toleratedRange(from: last.1, with: tolerance)
        if chekInRange.contains(secondLast.1) {
            return .linear
        }

        // TODO:- fix this
        return .polynomial
    }

    private func toleratedRange(from value: Double, with tolerance: Tolerance) -> Range<Double> {
        switch tolerance {
        case .none:
            return Range<Double>(uncheckedBounds: (lower: value * 0.99, upper: value * 1.01))
        case .low:
            return Range<Double>(uncheckedBounds: (lower: value * 0.9, upper: value * 1.1))
        case .medium:
            return Range<Double>(uncheckedBounds: (lower: value * 0.75, upper: value * 1.25))
        }
    }

}

