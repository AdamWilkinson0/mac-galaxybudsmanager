import Foundation
import IOBluetooth

public enum BudsFinder {

    // looks through paired devices for something that looks like buds
    public static func pairedBuds(address: String? = nil) -> IOBluetoothDevice? {
        guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return nil }

        if let address {
            let want = address.lowercased().replacingOccurrences(of: ":", with: "-")
            return paired.first { ($0.addressString ?? "").lowercased() == want }
        }

        return paired.first { ($0.name ?? "").localizedCaseInsensitiveContains("buds") }
    }
}

public extension Data {
    var hex: String {
        map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
