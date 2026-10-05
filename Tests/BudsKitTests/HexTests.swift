import Testing
import Foundation
@testable import BudsKit

@Test func hexString() {
    let d = Data([0x00, 0xab, 0x10])
    #expect(d.hex == "00 ab 10")
}
