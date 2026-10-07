// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_insider",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "flutter-insider", targets: ["flutter_insider"])
    ],
    dependencies: [
        .package(url: "https://github.com/useinsider/Insider-iOS-SDK", branch: "main")
    ],
    targets: [
        .target(
            name: "flutter_insider",
            dependencies: [
                .product(name: "InsiderMobile", package: "Insider-iOS-SDK"),
                .product(name: "InsiderGeofence", package: "Insider-iOS-SDK"),
                .product(name: "InsiderHybrid", package: "Insider-iOS-SDK"),
                .product(name: "InsiderMobileAdvancedNotification", package: "Insider-iOS-SDK")
            ],
            cSettings: [
                .headerSearchPath("include/flutter_insider")
            ]
        )
    ]
)
