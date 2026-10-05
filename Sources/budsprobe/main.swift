import Foundation
import IOBluetooth
import BudsKit

// usage:
//   budsprobe              list sdp services
//   budsprobe listen <ch>  open rfcomm channel and dump whatever comes in

var args = Array(CommandLine.arguments.dropFirst())
let addr = args.first { $0.contains(":") }
args.removeAll { $0 == addr }

guard let dev = BudsFinder.pairedBuds(address: addr) else {
    print("no buds found in paired devices")
    exit(1)
}

print("found: \(dev.name ?? "?")  \(dev.addressString ?? "?")  connected=\(dev.isConnected())")
setvbuf(stdout, nil, _IOLBF, 0)


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

func listServices() {
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
}


// MARK: listen

func listen(_ ch: BluetoothRFCOMMChannelID, seconds: Double) {
    let link = RfcommLink(device: dev)
    link.onClose = { print("channel closed by buds") }

    do {
        try link.open(channel: ch)
    } catch {
        print("open failed: \(error)")
        exit(2)
    }
    print("opened ch \(ch), listening \(Int(seconds))s (ctrl-c to stop)\n")

    let start = Date()
    Task {
        for await chunk in link.incoming {
            let t = String(format: "%7.3f", Date().timeIntervalSince(start))
            print("[\(t)] <- (\(chunk.count)) \(chunk.hex)")
        }
    }

    RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    link.close()
}


switch args.first {
case "listen":
    guard args.count > 1, let n = UInt8(args[1]) else {
        print("usage: budsprobe listen <channel> [seconds]")
        exit(1)
    }
    let secs = args.count > 2 ? Double(args[2]) ?? 60 : 60
    listen(n, seconds: secs)

default:
    listServices()
}
