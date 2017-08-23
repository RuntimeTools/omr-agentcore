// swift-tools-version:4.0
// omr-agentcore Swift 4 package

import PackageDescription

#if os(Linux)
   let excludePortDir = "ibmras/common/port/osx"
#else
   let excludePortDir = "ibmras/common/port/linux"
#endif

let package = Package(
    name: "omr-agentcore",
    products: [
        // omr-agentcore libraries.
        .library(name: "agentcore", type: .dynamic, targets: ["agentcore"]),
        .library(name: "hcapiplugin", type: .dynamic, targets: ["hcapiplugin"]),
        .library(name: "memplugin", type: .dynamic, targets: ["memplugin"]),
        .library(name: "cpuplugin", type: .dynamic, targets: ["cpuplugin"]),
        .library(name: "envplugin", type: .dynamic, targets: ["envplugin"]),
        .library(name: "mqttplugin", type: .dynamic, targets: ["mqttplugin"]),
        .library(name: "paho", type: .dynamic, targets: ["paho"])
    ],
    targets: [
        // omr-agentcore targets, one for each library.
      .target(name: "agentcore",
          exclude: [ "ibmras/common/port/aix",
                     "ibmras/common/port/windows",
                     "ibmras/common/data",
                     "ibmras/common/util/memUtils.cpp",
                     "ibmras/monitoring/connector/headless",
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
      .target(name: "mqttplugin", dependencies: ["paho"]),
      .target(name: "cpuplugin"),
      .target(name: "envplugin"),
      .target(name: "memplugin"),
      .target(name: "hcapiplugin")
    ]
)
