import XCTest
@testable import AlgoChecker

final class AlgoCheckerTests: XCTestCase {
    func testExample() { }

    func test_typeCheckerPasses() {
        // 1. Algorithm to test
        func simpleAlgo(_ input: [Int]) -> Int {
            return input.reduce(0, +)
        }

        // 2. Wrap in Operation
        let algoOperation = AlgorithmChecker.Operation<Int> { (inputProvider, completion) in
            let result = simpleAlgo(inputProvider.input())
            completion(result)
        }

        // 3. Find/assert algorithm complexity
        var checker = AlgorithmChecker()
        let result = checker.assert(algorithm: algoOperation, has: .linear, tolerance: .low)

        XCTAssertEqual(result, true)
    }

    func test_typeCheckerPassedWithQuadraticComplexAlgorithm_detectsItsQuadratic() {
        // TODO:-
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
