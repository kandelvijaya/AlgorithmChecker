import Foundation
import QuartzCore


/// Given a algorithm encapsulated in Operation, asserts weather the time
/// complexity of the algorithm matches the expected one.
///
/// This one doesnot parse the code and analyse. However, it runs the algorithm
/// feeding various sized of random input and then analyse the time/size graph
/// with some tolerance to offset system fluctuation.
///
/// There might be some false positive. This is WIP.
public struct AlgorithmChecker {

    public init() {}

    public enum TimeComplexity {
        case linear
        case logarithmic
        case quadratic
        case polynomial
    }

    typealias Second = Double
    typealias SampleSize = Int

    struct ComputeTimePoint {

        let size: SampleSize
        let computeTime: Second  // expressed in seconds

    }

    public enum Tolerance {
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
    /// Consideration:
    /// It doesnot make sense to provide same sample size for all algorithms.
    /// Especially if the algorithm is quadratic or polynomial then we can provide
    /// sample size that won't freeze the computer for days. To do such, we can
    /// accumulate result and analyse them and then provide next usable input size.
    struct SizeState {

        var timePoints: [ComputeTimePoint] = []

        mutating func addTimePoint(_ newTimePoint: ComputeTimePoint) {
            timePoints.append(newTimePoint)
        }

        func currentInputSize() -> Int? {
            return nextUsableSize(when: timePoints)
        }

        var currentComplexity: TimeComplexity {
            return ComputeTimePointAnalyzer().analyseComplexity(from: timePoints, with: .medium)
        }

        /// Calculates what would be the next best usable input size
        /// considering it should be substantial leap from current and
        /// it should not hang the computer comupting it. (quadratic & polynomial
        /// algorithm usually suffer from this one)
        ///
        /// NOTE:- If the last compute time was more than 10 seconds then don't proceed
        private func nextUsableSize(when previousTimePoints: [ComputeTimePoint]) -> SampleSize? {
            let possibleComplexity = currentComplexity
            let lastPoint = previousTimePoints.sorted { $0.size < $1.size }.last
            let lastSampleSize = lastPoint?.size ?? 2
            var possibleNextSize: SampleSize

            switch possibleComplexity {
            case .linear:
                //1. Check if we have used enough data sets
                if previousTimePoints.count > 512 { return nil }
                possibleNextSize = lastSampleSize ^ 2
            case .logarithmic:
                // return nlogn or a bit less
                if previousTimePoints.count > 512 { return nil }
                possibleNextSize = lastSampleSize * 2
            case .quadratic:
                // return a point which would not blow up processing
                possibleNextSize = lastSampleSize * 2
            case .polynomial:
                // return a point which would not blow up processing
                possibleNextSize = lastSampleSize * 2
            }

            if (lastPoint?.computeTime ?? 0) >= 10.0 {
                return nil
            } else {
                return possibleNextSize
            }
        }

    }


    struct ComputeTimePointAnalyzer {

        /// Returns time complexity of the algorithm based on sample data and tolerance
        ///
        /// - Parameters:
        ///   - sample: [ComputeTimePoint]
        ///   - tolerance: Tolerance to apply such that the system process affect can be negated
        /// - Returns: TimeComplexity
        /// TODO:- use a graph checking algorithm here.
        /// TODO:- Plot graph and feed into coreml model to detect. Investigate
        func analyseComplexity(from sample: [ComputeTimePoint], with tolerance: Tolerance) -> TimeComplexity {
            guard sample.count >= 2 else { return .linear }

            let amplifier: Double = 1000
            let tangents = sample.map {($0.size, ($0.computeTime * amplifier) / Double($0.size)) }.sorted { $0.0 < $1.0 } // time/size

            Swift.assert(tangents.count >= 2, "There are no enough data points to analyse")

            let last = tangents.last!
            let secondLast = tangents.dropLast().last!

            let chekInRange = toleratedRange(from: last.1, with: tolerance)
            if chekInRange.contains(secondLast.1) {
                return .linear
            }

            // TODO:- At this moment, we can only check for linear complexity.
            // TODO:- Add support for more.
            return .polynomial
        }

        private func toleratedRange(from value: Second, with tolerance: Tolerance) -> Range<Second> {
            switch tolerance {
            case .none:
                return Range<Second>(uncheckedBounds: (lower: value * 0.99, upper: value * 1.01))
            case .low:
                return Range<Second>(uncheckedBounds: (lower: value * 0.9, upper: value * 1.1))
            case .medium:
                return Range<Second>(uncheckedBounds: (lower: value * 0.75, upper: value * 1.25))
            }
        }


    }


    /// Randomized data source to feed into algorithm input
    public struct InputProvider {

        let currentSize: Int

        init?(state: SizeState) {
            guard let size = state.currentInputSize() else {
                return nil
            }
            self.currentSize = size
        }

        public func input<T>() -> T where T: Randomizabel {
            return T.random()
        }

        public func input<T>() -> T where T: Collection, T.Element: Randomizabel {
            let arr = Array<T.Element>(repeating: T.Element.random(), count: currentSize)
            return arr.random as! T
        }

    }


    /// Encapsulates the algorithm function.
    /// 1. The algorithm can use provided InputProvider to get the input.
    /// 2. The algorithm must call into the completion block supplied with the result.
    /// 3. `U` is the type of result the algorithm produces.
    public struct Operation<U> {

        public let fnBlock: (InputProvider, (U) -> Void) -> Void

        public init(_ fnBlock: @escaping (InputProvider, (U) -> Void) -> Void) {
            self.fnBlock = fnBlock
        }

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
    public mutating func assert<T>(algorithm: Operation<T>, has expectedComplexity: TimeComplexity, tolerance: Tolerance = .none) -> Bool {

        // Storage of the samples collected
        var timeKeeper: SizeState = SizeState()

        var ip = InputProvider(state: timeKeeper)
        while ip != nil {
            let startTime = CACurrentMediaTime()
            let executingSize = ip!.currentSize
            algorithm.fnBlock(ip!) { result in
                let stopTime = CACurrentMediaTime()
                let timePoint = ComputeTimePoint(size: executingSize, computeTime: stopTime - startTime)
                timeKeeper.addTimePoint(timePoint)
            }
            ip = InputProvider(state: timeKeeper)
        }

        return timeKeeper.currentComplexity == expectedComplexity
    }

}

