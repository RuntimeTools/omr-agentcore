// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
   let excludePortDir = "ibmras/common/port/osx"
#else
   let excludePortDir = "ibmras/common/port/linux"
#endif

let package = Package(
    name: "SwiftMetricsCore",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.

        .library(name: "agentcore", type: .dynamic, targets: ["agentcore"]),
        .library(name: "hcapiplugin", type: .dynamic, targets: ["hcapiplugin"]),
        .library(name: "memplugin", type: .dynamic, targets: ["memplugin"]),
        .library(name: "cpuplugin", type: .dynamic, targets: ["cpuplugin"]),
        .library(name: "envplugin", type: .dynamic, targets: ["envplugin"]),
        .library(name: "mqttplugin", type: .dynamic, targets: ["mqttplugin"]),
        .library(name: "paho", type: .dynamic, targets: ["paho"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
      .target(name: "agentcore",
          exclude: [ "ibmras/common/port/aix",
                     "ibmras/common/port/windows",
                     "ibmras/common/data",
                     "ibmras/common/util/memUtils.cpp",
                     excludePortDir
      ]),
      .target(name: "paho",
          exclude: [ "Windows Build",
              "build",
              "doc",
              "test",
              "src/MQTTClient.c",
              "src/MQTTVersion.c",
              "src/SSLSocket.c",
              "src/samples",
      ]),
      .target(name: "mqttplugin", dependencies: ["paho", "agentcore"]),
      .target(name: "cpuplugin"),
      .target(name: "envplugin"),
      .target(name: "memplugin"),
      .target(name: "hcapiplugin")
    ]
)
