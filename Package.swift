// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxSwiftBook5SampleCode",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RxSwiftBook5SampleCode",
            targets: ["RxSwiftBook5SampleCode"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .exact("6.0.0"))
    ],
    targets: [
        .target(
            name: "RxSwiftBook5SampleCode",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift")
            ]),
        .testTarget(
            name: "RxSwiftBook5SampleCodeTests",
            dependencies: ["RxSwiftBook5SampleCode"]),
    ]
)
