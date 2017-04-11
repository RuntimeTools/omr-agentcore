{
  "variables": {
    "srcdir%": "./src/ibmras",
    "pahosrcdir%": "./org.eclipse.paho.mqtt.c/src",
#    "externalbinariesdir%": "<(PRODUCT_DIR)/deploy/external/binaries",
    "externalbinariesdir%": "./plugins",
    'build_id%': '.<!(["python", "./generate_build_id.py"])',
    'coreversion%': '3.2.2',
  },
  "conditions": [
    ['OS=="aix"', {
      "variables": {
        "portdir%": "aix",
        "SHARED_LIB_SUFFIX": ".a",
      },
    }],
    ['OS=="linux"', {
      "variables": {
        "portdir%": "linux"
      },
    }],
    ['OS=="mac"', {
      "variables": {
        "portdir%": "osx"
      },
    }],
    ['OS=="win"', {
      "variables": {
        "portdir%": "windows"
      },
    }]
  ],

  "target_defaults": {
    "cflags_cc!": [ '-fno-exceptions' ],
    "defines": [ "EXPORT", "IBMRAS_DEBUG_LOGGING" ],
    "include_dirs": [ "src", "<(pahosrcdir)" ],
    "target_conditions": [
      ['_type=="shared_library"', {
        'product_prefix': '<(SHARED_LIB_PREFIX)',
        "conditions": [
          ['OS=="aix"', {
            'product_extension': 'a',
          },{
          }],
        ],
      }],
    ],
    "conditions": [
      ['OS=="aix"', {
        "defines": [ "_AIX", "AIX" ],
        "libraries": [ "-Wl,-bexpall,-brtllib,-G,-bernotok,-brtl,-L.,-bnoipath" ],
      }],
      ['OS=="mac"', {
        "defines": [ "__MACH__", "__APPLE__",  ],
         "libraries": [ "-undefined dynamic_lookup" ],
         "xcode_settings": {
            "OTHER_CPLUSPLUSFLAGS" : [ "-fexceptions" ],
         },
      }],
      ['OS=="linux"', {
        "defines": [ "_LINUX", "LINUX" ],
      }],
      ['OS=="win"', {
        "defines": [ "_WINDOWS", "WINDOWS"  ],
        "libraries": [ "Ws2_32" ],
        "msvs_settings": {
          "VCCLCompilerTool": {
            "AdditionalOptions": [
              "/EHsc",
              "/MD",
            ]
          },
        },
      }]
    ],
  },

  "targets": [
    {
      "target_name": "agentcore",
      "type": "shared_library",
      "sources": [ 
        "<(srcdir)/common/Logger.cpp",
        "<(srcdir)/common/LogManager.cpp",
        "<(srcdir)/common/MemoryManager.cpp",
        "<(srcdir)/common/util/FileUtils.cpp",
        "<(srcdir)/common/util/LibraryUtils.cpp",
        "<(srcdir)/common/port/<(portdir)/Thread.cpp",
        "<(srcdir)/common/port/<(portdir)/Process.cpp",
        "<(srcdir)/common/port/Lock.cpp",
        "<(srcdir)/common/port/ThreadData.cpp",
        "<(srcdir)/common/Properties.cpp",
        "<(srcdir)/common/PropertiesFile.cpp",
        "<(srcdir)/common/util/strUtils.cpp",
        "<(srcdir)/common/util/sysUtils.cpp",
        "<(INTERMEDIATE_DIR)/monitoring/agent/Agent.cpp",
        "<(srcdir)/monitoring/agent/threads/ThreadPool.cpp",
        "<(srcdir)/monitoring/agent/threads/WorkerThread.cpp",
        "<(srcdir)/monitoring/agent/SystemReceiver.cpp",
        "<(srcdir)/monitoring/connector/ConnectorManager.cpp",
        "<(srcdir)/monitoring/agent/Bucket.cpp",
        "<(srcdir)/monitoring/agent/BucketList.cpp",
        "<(srcdir)/monitoring/Plugin.cpp",
        "<(srcdir)/monitoring/connector/configuration/ConfigurationConnector.cpp",
      ],
      'variables': {
      	'corelevel%':'<(coreversion)<(build_id)',
      },
      'actions': [{
        'action_name': 'Set core reported version/build level',
        'inputs': [ "<(srcdir)/monitoring/agent/Agent.cpp" ],
        'outputs': [ "<(INTERMEDIATE_DIR)/monitoring/agent/Agent.cpp" ],
        'action': [
          'python',
          './replace_in_file.py',
          '<(srcdir)/monitoring/agent/Agent.cpp',
          '<(INTERMEDIATE_DIR)/monitoring/agent/Agent.cpp',
          '--from="99\.99\.99\.29991231"',
          '--to="<(corelevel)"',
          '-v'
         ],
      }],
    },
    {
      "target_name": "hcmqtt",
      "type": "shared_library",
      "sources": [
        "<(pahosrcdir)/Clients.c",
        "<(pahosrcdir)/Heap.c",
        "<(pahosrcdir)/LinkedList.c",
        "<(pahosrcdir)/Log.c",
        "<(pahosrcdir)/Messages.c",
        "<(pahosrcdir)/MQTTAsync.c",
        "<(pahosrcdir)/MQTTPacket.c",
        "<(pahosrcdir)/MQTTPacketOut.c",
        "<(pahosrcdir)/MQTTPersistence.c",
        "<(pahosrcdir)/MQTTPersistenceDefault.c",
        "<(pahosrcdir)/MQTTProtocolClient.c",
        "<(pahosrcdir)/MQTTProtocolOut.c",
        "<(pahosrcdir)/SocketBuffer.c",
        "<(pahosrcdir)/Socket.c",
        "<(pahosrcdir)/StackTrace.c",
        "<(pahosrcdir)/Thread.c",
        "<(pahosrcdir)/Tree.c",
        "<(pahosrcdir)/utf-8.c",
        "<(srcdir)/monitoring/connector/mqtt/MQTTConnector.cpp",
      ],
      "dependencies": [ "agentcore" ],
      "conditions": [
        [ 'node_byteorder=="big"', {
          "defines": [ "REVERSED" ], 
        }],
      ],
    },
    {
      "target_name": "cpuplugin",
      "type": "shared_library",
      "sources": [
        "<(srcdir)/monitoring/plugins/common/cpu/cpuplugin.cpp",
      ],
      "conditions": [
        ['OS=="win"', {
          "libraries": [ "Pdh" ],
        }],
        ['OS=="aix"', {
          "libraries": [ "-lperfstat" ],
        }],
      ],
    },
    {
      "target_name": "memoryplugin",
      "type": "shared_library",
      "sources": [
        "<(srcdir)/monitoring/plugins/common/memory/MemoryPlugin.cpp",
      ],
      "conditions": [
        ['OS=="win"', {
          "libraries": [ "Psapi" ],
        }],
      ],
    },
    {
      "target_name": "envplugin",
      "type": "shared_library",
      "sources": [
        "<(srcdir)/monitoring/plugins/common/environment/envplugin.cpp",
     ],
    },
   {
      "target_name": "hcapiplugin",
      "type": "shared_library",
      "sources": [
        "<(srcdir)/monitoring/connector/api/APIConnector.cpp",
      ],
      "dependencies": [ "agentcore" ],
    },
    {
      "target_name": "headlessplugin",
      "type": "shared_library",
      "sources": [
        "<(srcdir)/monitoring/connector/headless/HLConnector.cpp",
      ],
      "dependencies": [ "agentcore" ],
    },
    {
      "target_name": "external",
      "type": "none",
      "dependencies": [
      	"agentcore",
        "hcmqtt",
        "hcapiplugin",
        "cpuplugin",
        "envplugin",
        "memoryplugin",
        "headlessplugin",
      ],
      "copies": [
        {
          "destination": "./",
          "files": [
            "<(PRODUCT_DIR)/<(SHARED_LIB_PREFIX)agentcore<(SHARED_LIB_SUFFIX)",
          ],
        },
        {
          "destination": "./plugins",
          "files": [
            "<(PRODUCT_DIR)/<(SHARED_LIB_PREFIX)hcmqtt<(SHARED_LIB_SUFFIX)",
            "<(PRODUCT_DIR)/<(SHARED_LIB_PREFIX)cpuplugin<(SHARED_LIB_SUFFIX)",
            "<(PRODUCT_DIR)/<(SHARED_LIB_PREFIX)envplugin<(SHARED_LIB_SUFFIX)",
            "<(PRODUCT_DIR)/<(SHARED_LIB_PREFIX)memoryplugin<(SHARED_LIB_SUFFIX)",
            "<(PRODUCT_DIR)/<(SHARED_LIB_PREFIX)hcapiplugin<(SHARED_LIB_SUFFIX)",
            "<(PRODUCT_DIR)/<(SHARED_LIB_PREFIX)headlessplugin<(SHARED_LIB_SUFFIX)",
          ],
        },
      ],
    },
  ],
}

