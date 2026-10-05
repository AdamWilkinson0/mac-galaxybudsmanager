// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BudsManager",
    platforms: [ .macOS(.v14) ],
    targets: [
        .target(
            name: "BudsKit",
            linkerSettings: [ .linkedFramework("IOBluetooth") ]
        ),

        .executableTarget(
            name: "budsprobe",
            dependencies: [ "BudsKit" ],
            linkerSettings: [
                .linkedFramework("IOBluetooth"),
                // embed plist so the bluetooth permission prompt works for the cli
                .unsafeFlags([ "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Sources/budsprobe/Info.plist" ])
            ]
        ),

        .testTarget(
            name: "BudsKitTests",
            dependencies: [ "BudsKit" ]
        ),
    ]
)
