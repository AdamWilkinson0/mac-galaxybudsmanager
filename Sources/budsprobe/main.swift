import Foundation
import IOBluetooth
import BudsKit

let args = Array(CommandLine.arguments.dropFirst())
let addr = args.first { $0.contains(":") || $0.contains("-") }

guard let dev = BudsFinder.pairedBuds(address: addr) else {
    print("no buds found in paired devices")
    exit(1)
}

print("found: \(dev.name ?? "?")  \(dev.addressString ?? "?")  connected=\(dev.isConnected())")


// MARK: sdp

class SDPWaiter: NSObject {
    var done = false

    @objc func sdpQueryComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        print("sdp query finished, status \(status)")
        done = true
    }
}

func uuidList(_ rec: IOBluetoothSDPServiceRecord) -> [String] {
    guard let el = rec.getAttributeDataElement(0x0001) else { return [] }

    var out: [String] = []
    let items = (el.getArrayValue() as? [IOBluetoothSDPDataElement]) ?? [el]

    for item in items {
        if let u = item.getUUIDValue() {
            out.append((u as Data).hex.replacingOccurrences(of: " ", with: ""))
        }
    }
    return out
}

let waiter = SDPWaiter()
let res = dev.performSDPQuery(waiter)

if res != kIOReturnSuccess {
    print("couldnt start sdp query (\(res)), using cached records")
    waiter.done = true
}

let deadline = Date().addingTimeInterval(15)
while !waiter.done && Date() < deadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
}

let recs = (dev.services as? [IOBluetoothSDPServiceRecord]) ?? []
print("\n\(recs.count) service records\n")

for r in recs {
    var ch: BluetoothRFCOMMChannelID = 0
    let hasCh = r.getRFCOMMChannelID(&ch) == kIOReturnSuccess

    let name = r.getServiceName() ?? "(no name)"
    print("- \(name)")
    print("    rfcomm: \(hasCh ? String(ch) : "none")")
    print("    uuids:  \(uuidList(r).joined(separator: ", "))")
}
