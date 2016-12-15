import Foundation
import PackageDescription

let fm = FileManager.default

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

if fm.fileExists(atPath: "src/agentcore") == false {

   /// Module directory names
   let PAHO_SRC_DIR = "org.eclipse.paho.mqtt.c"
   let PAHO = "paho"
   let AGENT_CORE_DIR = "agentcore"
   let CPU_PLUGIN_DIR = "cpuplugin"
   let ENV_PLUGIN_DIR = "envplugin"
   let MEM_PLUGIN_DIR = "memplugin"
   let MQTT_PLUGIN_DIR = "mqttplugin"
   let API_PLUGIN_DIR = "hcapiplugin"
   let OSTREAM_PLUGIN_DIR = "ostreamplugin"
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

   ///moveSource function - moves the original source from its ibmras structure into its new swift module
   func moveSource(rootDir: String, pluginSrcDir: String, pluginTargetDir: String) throws {

      ///move plugin source to plugin directories - need to call this from rootDir
      _ = fm.changeCurrentDirectoryPath(rootDir)
      _ = fm.changeCurrentDirectoryPath(pluginSrcDir)
      let dirContents = try fm.contentsOfDirectory(atPath: fm.currentDirectoryPath)
      for file in dirContents {
         let targetDir = rootDir + FILE_SEPARATOR + pluginTargetDir
         _ = try fm.moveItem(atPath:file, toPath: targetDir + FILE_SEPARATOR + file)
      }
   }
   
   //relativePath function - given two filepaths under a common root, determine a relative path from the source to the target
   func relativePath(sourceFilePath: String, targetFilePath: String) -> String {
      var sourcePath = sourceFilePath.components(separatedBy: FILE_SEPARATOR)
      var targetPath = targetFilePath.components(separatedBy: "/")
      ///Remove the last elements of the paths (the file names)
      ///retain the last element of targetPath for reinsertion later
      let targetFile = targetPath.removeLast()
      _ = sourcePath.removeLast()
      //remove common directories from the start of the paths
      while !sourcePath.isEmpty && sourcePath.first == targetPath.first {
         _ = sourcePath.removeFirst()
         _ = targetPath.removeFirst()
      }
      var targetFilePath = ""
      for _ in sourcePath {
         targetFilePath += "../"
      }
      for dir in targetPath {
         targetFilePath += "\(dir)/"
      }
      return targetFilePath + targetFile
   }

   let rootDirPath = fm.currentDirectoryPath
   //restructure Paho
   _ = fm.changeCurrentDirectoryPath(PAHO_SRC_DIR)
   _ = try fm.createDirectory(atPath: "include", withIntermediateDirectories: false)
   _ = fm.changeCurrentDirectoryPath(rootDirPath)
   _ = try fm.moveItem(atPath: PAHO_SRC_DIR, toPath: SOURCE_DIR + FILE_SEPARATOR + PAHO)
   
   /// create the module directories
   for dir in MODULE_DIR_LIST {
      _ = try fm.createDirectory(atPath: SOURCE_DIR + FILE_SEPARATOR + dir + FILE_SEPARATOR + "include", 
                                 withIntermediateDirectories: true)
   }

   ///change directory to the src/ directory
   _ = fm.changeCurrentDirectoryPath(SOURCE_DIR)
   let srcDirPath = fm.currentDirectoryPath
   
   ///move plugin source to plugin directories
   try moveSource(rootDir: srcDirPath, pluginSrcDir: CPU_PLUGIN_SRC_DIR, pluginTargetDir: CPU_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: ENV_PLUGIN_SRC_DIR, pluginTargetDir: ENV_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: MEM_PLUGIN_SRC_DIR, pluginTargetDir: MEM_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: MQTT_CONNECTOR_SRC_DIR, pluginTargetDir: MQTT_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: API_CONNECTOR_SRC_DIR, pluginTargetDir: API_PLUGIN_DIR)
   try moveSource(rootDir: srcDirPath, pluginSrcDir: OSTREAM_CONNECTOR_SRC_DIR, pluginTargetDir: OSTREAM_PLUGIN_DIR)

   /// go back to the source directory
   _ = fm.changeCurrentDirectoryPath(srcDirPath)

   ///put the rest of ibmras under agentcore
   _ = try fm.moveItem(atPath: IBMRAS_DIR, toPath: AGENT_CORE_DIR + FILE_SEPARATOR + IBMRAS_DIR)


   ///put AgentExtensions.h into agentcore's include directory so the functions can be exported
   _ = try fm.moveItem(atPath: AGENT_CORE_DIR + FILE_SEPARATOR + MONITOR_SRC_DIR + AGENT_EXTENSIONS, 
                       toPath: AGENT_CORE_DIR + FILE_SEPARATOR + "include" + FILE_SEPARATOR + AGENT_EXTENSIONS)
   

   ///put properties dir into root so that it doesn't try to be a module
   _ =  try fm.moveItem(atPath: PROPERTIES_DIR, toPath: rootDirPath + FILE_SEPARATOR + PROPERTIES_DIR)


   ///Now for the file editing - the following needs to be changed in source files:
   /// 1. All source files need to refer to their compatriot header file relatively
   /// 2. All references to AgentExtensions.h in files need to be flattened, as we moved that to agentcore include
   /// 3. All non-standard declarations of platform (_Linux, LINUX, _LINUX) need to be standardised to __LINUX__

   /// 2. and 3. are the easy ones - let's do them first
   let encoding:String.Encoding = String.Encoding.utf8
   let linuxVariations = ["defined(_Linux)", "defined(LINUX)", "defined(_LINUX)", "defined (_LINUX)"]
   var fileEnum = fm.enumerator(atPath: srcDirPath)
   while let fn = fileEnum?.nextObject() {
      let fileName = String(describing: fn)
      ///only want source files or header files
      if fileName.hasSuffix(".cpp") || fileName.hasSuffix(".h") {
         var fileContents = try String(contentsOfFile: fileName, encoding: encoding)
         fileContents = fileContents.replacingOccurrences(of:MONITOR_SRC_DIR + AGENT_EXTENSIONS, with:AGENT_EXTENSIONS)
         for variation in linuxVariations {
            fileContents = fileContents.replacingOccurrences(of: variation, with: "defined(__linux__)")
         }
         try fileContents.write(toFile: fileName, atomically: true, encoding: encoding)
      }
      ///Workaround for having a method name that is already used by macOS
      if fileName.hasSuffix("Heap.c") {
         var fileContents = try String(contentsOfFile: fileName, encoding: encoding)
         fileContents = fileContents.replacingOccurrences(of: "roundup", with: "roundup_")
         try fileContents.write(toFile: fileName, atomically: true, encoding: encoding)
      }
   }
   
   //MQTT headers are required by the mqttplugin's files
   var targetWorkingDir = srcDirPath + FILE_SEPARATOR + MQTT_PLUGIN_DIR
   _ = fm.changeCurrentDirectoryPath(targetWorkingDir)
   fileEnum = fm.enumerator(atPath: targetWorkingDir)
   while let fn = fileEnum?.nextObject() {
      let fileName = String(describing: fn)
      if fileName != "include" {
         var fileContents = try String(contentsOfFile: fileName, encoding: encoding)
         fileContents = fileContents.replacingOccurrences(of: "#include \"MQTT", 
                                                          with:"#include \"../"+PAHO+"/"+SOURCE_DIR+"/MQTT")
         ///we also need to do this with Heap.h
         fileContents = fileContents.replacingOccurrences(of: "#include \"Heap.h", 
                                                          with:"#include \"../"+PAHO+"/"+SOURCE_DIR+"/Heap.h")
         try fileContents.write(toFile: fileName, atomically: true, encoding: encoding)
      }
   }
   
   ///PAHO is now complete. All uncomplete modules (apart from agentcore) now have a single source file and a single header
   ///file in the same directory. Let's change those files now.
   var workingModules = [CPU_PLUGIN_DIR, ENV_PLUGIN_DIR, MEM_PLUGIN_DIR, MQTT_PLUGIN_DIR, API_PLUGIN_DIR, OSTREAM_PLUGIN_DIR]
   var source = "", header = "", headerRegex = ""
   let prevWorkingDir = fm.currentDirectoryPath
   for dir in workingModules {
      let targetWorkingDir = srcDirPath + FILE_SEPARATOR + dir
      _ = fm.changeCurrentDirectoryPath(targetWorkingDir)
      fileEnum = fm.enumerator(atPath: targetWorkingDir)
      while let fn = fileEnum?.nextObject() {
         let fileName = String(describing: fn)
         if fileName != "include" {
            if fileName.hasSuffix(".cpp") {
               source = fileName
            } else {
               /// need a \ on the . of .h for the regex to match it
               headerRegex = fileName.replacingOccurrences(of: ".", with: "\\.")
               header = fileName
            }
         }
      }
      var fileContents = try String(contentsOfFile: source, encoding: encoding)
      fileContents = fileContents.replacingOccurrences(of: "#include.*?"+headerRegex, with:"#include \"\(header)",
                                                       options: .regularExpression)
      fileContents = fileContents.replacingOccurrences(of: "#include \""+IBMRAS_DIR, 
                                                       with:"#include \"../"+AGENT_CORE_DIR+"/"+IBMRAS_DIR)
      try fileContents.write(toFile: source, atomically: true, encoding: encoding)
      fileContents = try String(contentsOfFile: header, encoding: encoding)
      fileContents = fileContents.replacingOccurrences(of: "#include \""+IBMRAS_DIR, 
                                                       with:"#include \"../"+AGENT_CORE_DIR+"/"+IBMRAS_DIR)
      try fileContents.write(toFile: header, atomically: true, encoding: encoding)
       
   }
   _ = fm.changeCurrentDirectoryPath(prevWorkingDir)
   
   //finally, we alter agentcore's headers to become relative.
   targetWorkingDir = srcDirPath + FILE_SEPARATOR + AGENT_CORE_DIR
   _ = fm.changeCurrentDirectoryPath(targetWorkingDir)
   fileEnum = fm.enumerator(atPath: targetWorkingDir)
   while let fn = fileEnum?.nextObject() {
      let fileName = String(describing: fn)
      //ignore the include directory and anything that isn't a header or source file
      if fileName.hasPrefix(IBMRAS_DIR) && (fileName.hasSuffix(".cpp") || fileName.hasSuffix(".h")) {
         var fileContents = try String(contentsOfFile: fileName, encoding: encoding)
         while let foundRange = fileContents.range(of: "#include [\"<]"+IBMRAS_DIR+".*?[\">]", options: .regularExpression) {
            var foundString = fileContents.substring(with: foundRange)
            ///get rid of the include part and the final quote
            foundString = foundString.substring(from: foundString.index(foundString.startIndex, offsetBy: 10))
            foundString = foundString.substring(to: foundString.index(foundString.endIndex, offsetBy: -1))
            ///replace with the new concocted string
            fileContents.replaceSubrange(foundRange, with: "#include \"\(relativePath(sourceFilePath: fileName, targetFilePath: foundString))\"")
         }
         try fileContents.write(toFile: fileName, atomically: true, encoding: encoding)
      }
   }  
}

#if os(Linux)
   let excludePortDir = "src/agentcore/ibmras/common/port/osx"
#else
   let excludePortDir = "src/agentcore/ibmras/common/port/linux"
#endif

let package = Package(
   name: "omr-agentcore",
   targets: [
      Target(name: "mqttplugin", dependencies: [.Target(name: "paho"),
                                                   .Target(name: "agentcore")]),
      Target(name: "cpuplugin", dependencies: [.Target(name: "agentcore")]),
      Target(name: "envplugin", dependencies: [.Target(name: "agentcore")]),
      Target(name: "memplugin", dependencies: [.Target(name: "agentcore")]),
      Target(name: "hcapiplugin", dependencies: [.Target(name: "agentcore")])
   ],
   exclude: [ "src/agentcore/ibmras/common/port/aix",
              "src/agentcore/ibmras/common/port/windows",
              "src/agentcore/ibmras/common/data",
              "src/agentcore/ibmras/common/util/memUtils.cpp",
              "src/ostreamplugin",
              "src/paho/Windows Build",
              "src/paho/build",
              "src/paho/doc",
              "src/paho/test",
              "src/paho/src/MQTTClient.c",
              "src/paho/src/MQTTVersion.c",
              "src/paho/src/SSLSocket.c",
              "src/paho/src/samples",
              excludePortDir
   ]
)
