import Foundation
import IOBluetooth

public enum LinkError: Error {
    case noDevice
    case openFailed(IOReturn)
    case notOpen
    case writeFailed(IOReturn)
}

// wraps one rfcomm channel, incoming bytes come out of `incoming`
public final class RfcommLink: NSObject, IOBluetoothRFCOMMChannelDelegate {

    public let device: IOBluetoothDevice
    var chan: IOBluetoothRFCOMMChannel?

    public let incoming: AsyncStream<Data>
    private var cont: AsyncStream<Data>.Continuation

    public var onClose: (() -> Void)?

    public init(device: IOBluetoothDevice) {
        self.device = device
        var c: AsyncStream<Data>.Continuation!
        incoming = AsyncStream { c = $0 }
        cont = c
        super.init()
    }

    public var isOpen: Bool { chan?.isOpen() ?? false }

    public func open(channel id: BluetoothRFCOMMChannelID) throws {
        var ch: IOBluetoothRFCOMMChannel?
        let r = device.openRFCOMMChannelSync(&ch, withChannelID: id, delegate: self)

        guard r == kIOReturnSuccess, let ch else { throw LinkError.openFailed(r) }
        chan = ch
    }

    public func write(_ data: Data) throws {
        guard let chan, chan.isOpen() else { throw LinkError.notOpen }

        var bytes = [UInt8](data)
        let r = chan.writeSync(&bytes, length: UInt16(bytes.count))
        if r != kIOReturnSuccess { throw LinkError.writeFailed(r) }
    }

    public func close() {
        chan?.close()
        chan = nil
    }

    // MARK: delegate

    public func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let d = Data(bytes: dataPointer, count: dataLength)
        cont.yield(d)
    }

    public func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        chan = nil
        onClose?()
    }
}
