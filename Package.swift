import Foundation
import PackageDescription

#if os(Linux)
   let fm = NSFileManager.defaultManager()
#else
   let fileManager = FileManager.default()
#endif


///need to drill down into the omr-agentcore directory from where we are
if fm.currentDirectoryPath.contains("omr-agentcore") == false {
   ///then we're not in the right directory - go look for agentcore in the Packages directory
   _ = fm.changeCurrentDirectoryPath("Packages")
   let dirContents = try fm.contentsOfDirectory(atPath: fm.currentDirectoryPath)
   for dir in dirContents {
      if dir.contains("omr-agentcore") {
         //that's where we want to be!
         _ = fm.changeCurrentDirectoryPath(dir)
      }
   }
}

if fm.fileExists(atPath: "src/libagentcore") == false {

   /// Constant module directory names
   let PAHO = "org.eclipse.paho.mqtt.c"
   let AGENT_CORE_DIR = "libagentcore"
   let CPU_PLUGIN_DIR = "libcpuplugin"
   let ENV_PLUGIN_DIR = "libenvplugin"
   let MEM_PLUGIN_DIR = "libmemplugin"
   let MQTT_PLUGIN_DIR = "libmqttplugin"
   let API_PLUGIN_DIR = "libhcapiplugin"
   let OSTREAM_PLUGIN_DIR = "libostreamplugin"
   let MODULE_DIR_LIST = [AGENT_CORE_DIR, CPU_PLUGIN_DIR, ENV_PLUGIN_DIR, MEM_PLUGIN_DIR,
                          MQTT_PLUGIN_DIR, API_PLUGIN_DIR, OSTREAM_PLUGIN_DIR]

   ///Source directory name
   let SOURCE_DIR = "src"

   ///file seperator
   let FILE_SEPARATOR="/"

   ///module-specific source directories
   let IBMRAS_DIR = "ibmras"
   let PROPERTIES_DIR = "properties"
   let MONITOR_SRC_DIR=IBMRAS_DIR + FILE_SEPARATOR + "monitoring" + FILE_SEPARATOR
   let PLUGINS_SRC_DIR=MONITOR_SRC_DIR + "plugins" + FILE_SEPARATOR + "common" + FILE_SEPARATOR
   let CPU_PLUGIN_SRC_DIR=PLUGINS_SRC_DIR+"cpu"
   let MEM_PLUGIN_SRC_DIR=PLUGINS_SRC_DIR+"memory"
   let ENV_PLUGIN_SRC_DIR=PLUGINS_SRC_DIR+"environment"
   let CONNECTOR_SRC_DIR=MONITOR_SRC_DIR + "connector" + FILE_SEPARATOR
   let MQTT_CONNECTOR_SRC_DIR = CONNECTOR_SRC_DIR + "mqtt"
   let OSTREAM_CONNECTOR_SRC_DIR = CONNECTOR_SRC_DIR + "ostream"
   let API_CONNECTOR_SRC_DIR = CONNECTOR_SRC_DIR + "api"

   ///Public header file names
   let AGENT_EXTENSIONS = "AgentExtensions.h"

   ///moveSource function
   func moveSource(rootDir: String, pluginSrcDir: String, pluginTargetDir: String) throws {

      ///move plugin source to plugin directories - need to call this from rootDir
      _ = fm.changeCurrentDirectoryPath(rootDir)
      _ = fm.changeCurrentDirectoryPath(pluginSrcDir)
      print("Current directory is " + fm.currentDirectoryPath)
      let dirContents = try fm.contentsOfDirectory(atPath: fm.currentDirectoryPath)
      for file in dirContents {
         let targetDir = rootDir + FILE_SEPARATOR + pluginTargetDir
         print("Attempting to move " + file + " to " + targetDir + FILE_SEPARATOR + file)
         _ = try fm.moveItem(atPath:file, toPath: targetDir + FILE_SEPARATOR + file)
      }
   }

   let rootDirPath = fm.currentDirectoryPath
   print("Current directory is " + rootDirPath)
   print("Attempting to move " + PAHO + " to " + SOURCE_DIR + FILE_SEPARATOR + PAHO)
   _ = try fm.moveItem(atPath: PAHO, toPath: SOURCE_DIR + FILE_SEPARATOR + PAHO)

   ///change directory to the src/ directory
   _ = fm.changeCurrentDirectoryPath(SOURCE_DIR)
   let srcDirPath = fm.currentDirectoryPath
   print("Current directory is " + srcDirPath)

   /// create the module directories
   for dir in MODULE_DIR_LIST {
      _ = try fm.createDirectory(atPath: dir, withIntermediateDirectories: false)
   }

   ///move plugin source to plugin directories
   try moveSource(rootDir: srcDirPath, pluginSrcDir: CPU_PLUGIN_SRC_DIR, pluginTargetDir: CPU_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: ENV_PLUGIN_SRC_DIR, pluginTargetDir: ENV_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: MEM_PLUGIN_SRC_DIR, pluginTargetDir: MEM_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: MQTT_CONNECTOR_SRC_DIR, pluginTargetDir: MQTT_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: API_CONNECTOR_SRC_DIR, pluginTargetDir: API_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: OSTREAM_CONNECTOR_SRC_DIR, pluginTargetDir: OSTREAM_PLUGIN_DIR)

   /// go back to the source directory
   _ = fm.changeCurrentDirectoryPath(srcDirPath)

   ///put the rest of ibmras under libagentcore
   _ = try fm.moveItem(atPath: IBMRAS_DIR, toPath: AGENT_CORE_DIR + FILE_SEPARATOR + IBMRAS_DIR)


   ///put AgentExtensions.h into libagentcore's include directory so the functions can be exported
   _ = try fm.createDirectory(atPath: AGENT_CORE_DIR + FILE_SEPARATOR + "include", withIntermediateDirectories: false)
   _ = try fm.moveItem(atPath: AGENT_CORE_DIR + FILE_SEPARATOR + MONITOR_SRC_DIR + AGENT_EXTENSIONS, 
                       toPath: AGENT_CORE_DIR + FILE_SEPARATOR + "include" + FILE_SEPARATOR + AGENT_EXTENSIONS)
   

   ///put properties dir into root so that it doesn't try to be a module
   _ =  try fm.moveItem(atPath: PROPERTIES_DIR, toPath: rootDirPath + FILE_SEPARATOR + PROPERTIES_DIR)


   ///Now for the file editing - the following needs to be changed in source files:
   /// 1. All source files need to refer to their compatriot header file relatively
   /// 2. All references to AgentExtensions.h in libagentcore files need to be changed, as we moved that to include
   /// 3. All non-standard declarations of platform (_Linux, LINUX, _LINUX) need to be standardised to __LINUX__
   let linuxVariations = ["defined(_Linux)", "defined(LINUX)", "defined(_LINUX)"]
   let fileEnum = fm.enumerator(atPath: srcDirPath)
   while let fileName = fileEnum?.nextObject() as? String {
      print(fileName)
      ///only want source files
      if fileName.hasSuffix("cpp") {
         var encoding : NSStringEncoding = NSUTF8StringEncoding
         var fileContents = try String(contentsOfFile: fileName, usedEncoding: &encoding)
         fileContents = fileContents.replacingOccurrences(of:MONITOR_SRC_DIR + AGENT_EXTENSIONS, with:AGENT_EXTENSIONS)
         for variation in linuxVariations {
            fileContents = fileContents.replacingOccurrences(of: variation, with: "defined(__linux__)")
         }
         try fileContents.write(toFile: fileName, atomically: true, encoding: encoding)
      }
   }

}

#if os(Linux)
   let excludePortDir = "src/libagentcore/ibmras/common/port/osx"
#else
   let excludePortDir = "src/libagentcore/ibmras/common/port/linux"
#endif

let package = Package(
   name: "omr-agentcore",
   targets: [
      Target(name: "libmqttplugin", dependencies: [.Target(name: "org.eclipse.paho.mqtt.c")]),
      Target(name: "libcpuplugin", dependencies: [.Target(name: "libagentcore")]),
      Target(name: "libenvplugin", dependencies: [.Target(name: "libagentcore")]),
      Target(name: "libmemplugin", dependencies: [.Target(name: "libagentcore")]),
      Target(name: "libostreamplugin", dependencies: [.Target(name: "libagentcore")]),
      Target(name: "libhcapiplugin", dependencies: [.Target(name: "libagentcore")])
   ],
   exclude: [ "src/libagentcore/ibmras/common/port/aix",
              "src/libagentcore/ibmras/common/port/windows",
              "src/libagentcore/ibmras/common/data",
              "src/libagentcore/ibmras/common/util/memUtils.cpp",
              "src/org.eclipse.paho.mqtt.c/Windows Build",
              "src/org.eclipse.paho.mqtt.c/build",
              "src/org.eclipse.paho.mqtt.c/doc",
              "src/org.eclipse.paho.mqtt.c/test",
              "src/org.eclipse.paho.mqtt.c/src/MQTTClient.c",
              "src/org.eclipse.paho.mqtt.c/src/MQTTVersion.c",
              "src/org.eclipse.paho.mqtt.c/src/SSLSocket.c",
              "src/org.eclipse.paho.mqtt.c/src/samples",
              excludePortDir
   ]
)