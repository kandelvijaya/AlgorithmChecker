import XCTest
@testable import AlgoChecker

final class AlgoCheckerTests: XCTestCase {
    func testExample() { }

    func test_typeCheckerPasses() {
        func simpleAlgo(_ input: [Int]) -> Int {
            return input.reduce(0, +)
        }

        let algoOperation = AlgorithmChecker.Operation<Int> { (inputProvider, completion) in
            let result = simpleAlgo(inputProvider.input())
            completion(result)
            print(result)
        }

        var checker = AlgorithmChecker()
        let result = checker.assert(algorithm: algoOperation, has: .linear, tolerance: .low)
        XCTAssertEqual(result, true)
    }

    func test_typeCheckerPassedWithQuadraticComplexAlgorithm_detectsItsQuadratic() {
        
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
