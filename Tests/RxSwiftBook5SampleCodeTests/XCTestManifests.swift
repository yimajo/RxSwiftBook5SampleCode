import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RxSwiftBook5SampleCodeTests.allTests),
    ]
}
#endif
