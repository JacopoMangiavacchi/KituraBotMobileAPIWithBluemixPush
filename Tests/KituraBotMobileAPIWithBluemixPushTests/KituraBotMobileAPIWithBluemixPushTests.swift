import XCTest
@testable import KituraBotMobileAPIWithBluemixPush

class KituraBotMobileAPIWithBluemixPushTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(KituraBotMobileAPIWithBluemixPush().text, "Hello, World!")
    }


    static var allTests : [(String, (KituraBotMobileAPIWithBluemixPushTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
