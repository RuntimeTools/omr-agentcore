#default installation is relative to this
PAHO_DIR=./org.eclipse.paho.mqtt.c
PAHO_SRC=${PAHO_DIR}/src
OMR-AGENTCORE=.
OMR-AGENTCORE_SRC=${OMR-AGENTCORE}/src/ibmras
OUTPUT=./output
OMR_SRC_INCLUDE=./buildDeps/omr/include_core
#-------------------------------------------------------------------------------------------
#Output directories i.e. where the files are going to be built
#-------------------------------------------------------------------------------------------

COMMON_OUT=${OUTPUT}/common
CONNECTOR_OUT=${OUTPUT}/connectors
AGENT_OUT=${OUTPUT}/agent
PLUGIN_OUT=${OUTPUT}/plugins
INSTALL_DIR=${OUTPUT}/deploy
#OMR_OUT=${OUTPUT}/java
OMR_OUT=${OUTPUT}/omr
NODE_OUT=${OUTPUT}/node
PAHO_OUT=${OUTPUT}/paho
HC_OUT=${OMR_OUT}

#-------------------------------------------------------------------------------------------
# conditional include of connector directory
#-------------------------------------------------------------------------------------------
COPY_CONNECTOR=cp ${CONNECTOR_OUT}/*.${LIB_EXT} ${INSTALL_DIR}/plugins

#-------------------------------------------------------------------------------------------
#Objects files which make up various components
#-------------------------------------------------------------------------------------------
COMMON_OBJS=${COMMON_OUT}/Logger.o ${COMMON_OUT}/LogManager.o ${COMMON_OUT}/FileUtils.o ${COMMON_OUT}/LibraryUtils.o ${COMMON_OUT}/Thread.o ${COMMON_OUT}/Lock.o ${COMMON_OUT}/Process.o ${COMMON_OUT}/ThreadData.o ${COMMON_OUT}/Properties.o ${COMMON_OUT}/PropertiesFile.o ${COMMON_OUT}/strUtils.o ${COMMON_OUT}/sysUtils.o ${COMMON_OUT}/MemoryManager.o 
HL_CONNECTOR_OBJS=${CONNECTOR_OUT}/HLConnector.o ${CONNECTOR_OUT}/HLConnectorPlugin.o
API_CONNECTOR_OBJS=${CONNECTOR_OUT}/APIConnector.o ${COMMON_OUT}/strUtils.o ${COMMON_OUT}/MemoryManager.o ${COMMON_OUT}/Logger.o ${COMMON_OUT}/LogManager.o ${COMMON_OUT}/Lock.o
AGENT_OBJS=${ASM_OBJS} ${COMMON_OBJS} ${AGENT_OUT}/agent.o ${AGENT_OUT}/ThreadPool.o ${AGENT_OUT}/WorkerThread.o ${AGENT_OUT}/SystemReceiver.o ${AGENT_OUT}/ConnectorManager.o ${AGENT_OUT}/Bucket.o ${AGENT_OUT}/BucketList.o ${AGENT_OUT}/Plugin.o  ${AGENT_OUT}/ConfigurationConnector.o 

PAHO_ASYNC_OBJS=${PAHO_OUT}/Clients.o ${PAHO_OUT}/Heap.o ${PAHO_OUT}/LinkedList.o ${PAHO_OUT}/Log.o ${PAHO_OUT}/Messages.o ${PAHO_OUT}/MQTTAsync.o ${PAHO_OUT}/MQTTPacket.o ${PAHO_OUT}/MQTTPacketOut.o ${PAHO_OUT}/MQTTPersistence.o ${PAHO_OUT}/MQTTPersistenceDefault.o ${PAHO_OUT}/MQTTProtocolClient.o ${PAHO_OUT}/MQTTProtocolOut.o ${PAHO_OUT}/SocketBuffer.o ${PAHO_OUT}/Socket.o ${PAHO_OUT}/StackTrace.o ${PAHO_OUT}/Thread.o ${PAHO_OUT}/Tree.o ${PAHO_OUT}/utf-8.o
MQTT_CONNECTOR_OBJS=${CONNECTOR_OUT}/MQTTConnector.o ${COMMON_OUT}/strUtils.o ${COMMON_OUT}/sysUtils.o ${COMMON_OUT}/Logger.o ${COMMON_OUT}/LogManager.o ${COMMON_OUT}/Properties.o ${COMMON_OUT}/Process.o ${COMMON_OUT}/Lock.o ${COMMON_OUT}/MemoryManager.o
OSTREAM_CONNECTOR_OBJS = ${CONNECTOR_OUT}/OStreamConnector.o 
TESTPLUGIN_OBJS=${PLUGIN_OUT}/plugin.o
OSPLUGIN_OBJS=${PLUGIN_OUT}/osplugin.o ${PLUGIN_OUT}/os${OS}.o


OMR_OBJS = ${OMR_OUT}/MethodLookupProvider.o ${OMR_OUT}/NativeMemoryDataProvider.o ${OMR_OUT}/CpuDataProvider.o ${OMR_OUT}/TraceDataProvider.o  ${OMR_OUT}/MemoryCountersDataProvider.o ${OMR_OUT}/healthcenter.o
ENVPLUGIN_OBJS=${PLUGIN_OUT}/envplugin.o
CPUPLUGIN_OBJS=${PLUGIN_OUT}/cpuplugin.o
MEMPLUGIN_OBJS=${PLUGIN_OUT}/MemoryPlugin.o

#-------------------------------------------------------------------------------------------
#Library names
#-------------------------------------------------------------------------------------------
AGENT_LIB=${AGENT_OUT}/agent.${ARC_EXT}
MQTT_LIB=${CONNECTOR_OUT}/${LIB_PREFIX}hcmqtt.${ARC_EXT}
OSTREAM_LIB=${CONNECTOR_OUT}/ostream.${ARC_EXT}

#-------------------------------------------------------------------------------------------
#Compilation / build configuration parameters
#-------------------------------------------------------------------------------------------
AGENTCORE-INCS=-I${OMR-AGENTCORE}/src
INCS=-Isrc
MQTT_INCS=-I${PAHO_SRC}
HC_EXPORT=-DEXPORT
RC_COMPILE=


default: all
#do not change the position of this include
include ${BUILD}.mk


#-------------------------------------------------------------------------------------------
#Components to allow specific sub-builds rather than everything
#-------------------------------------------------------------------------------------------
CONNECTORS=${CONNECTOR_OUT}/${LIB_PREFIX}hcmqtt.${LIB_EXT} ${CONNECTOR_OUT}/${LIB_PREFIX}apiplugin.${LIB_EXT} #${CONNECTOR_OUT}/libostream.${LIB_EXT}
AGENT=${AGENT_OUT}/${LIB_PREFIX}monagent.${LIB_EXT}
#PLUGINS=${PLUGIN_OUT}/libplugin.${LIB_EXT} ${PLUGIN_OUT}/libosplugin.${LIB_EXT}
PLUGINS=${PLUGIN_OUT}/libplugin.${LIB_EXT}
LOG_PLUGIN=${PLUGIN_OUT}/${LIB_PREFIX}logplugin.${LIB_EXT} 
COMMON_PLUGINS=${PLUGIN_OUT}/${LIB_PREFIX}envplugin.${LIB_EXT} ${PLUGIN_OUT}/${LIB_PREFIX}cpuplugin.${LIB_EXT} ${PLUGIN_OUT}/${LIB_PREFIX}memoryplugin.${LIB_EXT}#${PLUGIN_OUT}/libosplugin.${LIB_EXT} 
NODE_PLUGINS=${PLUGIN_OUT}/${LIB_PREFIX}nodegcplugin.${LIB_EXT} ${PLUGIN_OUT}/${LIB_PREFIX}nodeenvplugin.${LIB_EXT}
#NODE_PLUGINS=${PLUGIN_OUT}/${LIB_PREFIX}nodeprofplugin.${LIB_EXT}
OBJECTS=${AGENT} ${CONNECTORS} ${PLUGINS} ${TEST} 
CORE_AGENT=${OMR_OUT}/${LIB_PREFIX}agentcore.${LIB_EXT}
JAVA_AGENT=${OMR_OUT}/${LIB_PREFIX}healthcenter.${LIB_EXT}
OMR_AGENT=${OMR_OUT}/${LIB_PREFIX}healthcenter.${LIB_EXT}

#-------------------------------------------------------------------------------------------
#Top level targets i.e. those that can be invoked from the command line
#-------------------------------------------------------------------------------------------
all: setup common ${OBJECTS}
	@echo "All components now built"
	
res:
	${RC_COMPILE}
	@echo "Resource compile complete"
	
common: setup ${COMMON_OBJS}
	@echo "Common objects build complete" 

connectors: setup ${CONNECTORS}
	@echo "Connectors build complete"

agent: setup common ${AGENT}
	@echo "Agent build complete"
	
plugins: setup common ${PLUGINS}
	@echo "Plugin build complete"

omr: HC_OUT=${OMR_OUT}
omr: setup common ${OMR_AGENT} ${CONNECTORS} ${PLUGINS} 	
	@echo "omr build complete"

test: setup common ${CONNECTORS} ${AGENT} ${TEST}
	@echo "Test build complete"
	
#core: HC_OUT=${CORE_OUT}
core: setup res common ${CORE_AGENT} ${CONNECTORS} ${ENVPLUGIN_OBJS} ${CPUPLUGIN_OBJS} ${MEMPLUGIN_OBJS} ${COMMON_PLUGINS}
	@echo "Core build complete"	

#-------------------------------------------------------------------------------------------
#Libraries
#-------------------------------------------------------------------------------------------	
${AGENT_OUT}/${LIB_PREFIX}monagent.${LIB_EXT}: ${COMMON_OBJS} ${AGENT_OBJS}
	${LINK} ${LINK_OPT} ${LIBFLAGS} ${LIB_OBJOPT} ${EXELIBS} ${COMMON_OBJS} ${AGENT_OBJS} 
	${ARCHIVE} ${AGENT_OBJS}
	@echo "Agent lib built"
	
${PLUGIN_OUT}/libplugin.${LIB_EXT}: ${TESTPLUGIN_OBJS}
	${LINK} ${LINK_OPT} ${LIBFLAGS} ${LIB_OBJOPT} ${TESTPLUGIN_OBJS} ${COMMON_OBJS} ${EXELIBS} 
	@echo "Plugin lib built"
	
${PLUGIN_OUT}/${LIB_PREFIX}cpuplugin.${LIB_EXT}: ${CPUPLUGIN_OBJS}
	${LINK} ${LINK_OPT} ${LIBFLAGS} ${CPUFLAG} ${LIB_OBJOPT} ${CPUPLUGIN_OBJS} ${EXELIBS}
	@echo "CPU lib built"

${PLUGIN_OUT}/${LIB_PREFIX}envplugin.${LIB_EXT}: ${ENVPLUGIN_OBJS}
	${LINK} ${LINK_PLUG} ${LIBFLAGS} ${LIB_OBJOPT} ${ENVPLUGIN_OBJS} ${EXELIBS} 
	@echo "Environment lib built"
	
${PLUGIN_OUT}/${LIB_PREFIX}memoryplugin.${LIB_EXT}: ${MEMPLUGIN_OBJS}
	${LINK} ${LINK_PLUG} ${LIBFLAGS} ${LIB_OBJOPT} ${MEMPLUGIN_OBJS} ${EXELIBS} 
	@echo "Memory lib built"
	
${CONNECTOR_OUT}/${LIB_PREFIX}hcmqtt.${LIB_EXT}: ${MQTT_CONNECTOR_OBJS} ${PAHO_ASYNC_OBJS} ${COMMON_OBJS}
	${LINK} ${LINK_OPT} ${LIBFLAGS} ${LIB_OBJOPT} ${MQTT_CONNECTOR_OBJS} ${PAHO_ASYNC_OBJS} ${MQTT_LIB_OPTIONS} ${LD_OPT} ${EXELIBS} ${EXEFLAGS}
	@echo "MQTT connector lib built"

${CONNECTOR_OUT}/${LIB_PREFIX}apiplugin.${LIB_EXT}: ${API_CONNECTOR_OBJS} ${COMMON_OBJS}
	${LINK} ${LINK_OPT} ${LIBFLAGS} ${LIB_OBJOPT} ${API_CONNECTOR_OBJS} ${LD_OPT} ${EXELIBS} ${EXEFLAGS}
	@echo "InProcess connector lib built"

${OMR_OUT}/${LIB_PREFIX}agentcore.${LIB_EXT}: ${AGENT_OBJS}
	${LINK} ${LINK_OPT}  ${LIBFLAGS} ${LIB_OBJOPT} ${AGENT_OBJS} ${LD_OPT} ${EXELIBS} ${EXEFLAGS}
	@echo "core Healthcenter lib built"

#--------------------------------------------------------------------------------------------
#Test harness
#--------------------------------------------------------------------------------------------
${TEST_OUT}/test${EXE_EXT}: ${TEST_OBJS}
	${LINK} ${LINK_OPT} ${LIBPATH}"${AGENT_OUT}" ${EXEFLAGS} ${LIB_OBJOPT} ${TEST_OBJS} ${EXELIBS} ${MONAGENT} ${LD_OPT} ${COMMON_OBJS}
	@echo "Test harness built"
	

#---------------------------------------------------------------------------------------------
#Individual object files
#---------------------------------------------------------------------------------------------
${AGENT_OUT}/agent.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -I"./connector/mqtt" -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/agent/Agent.cpp
	
${AGENT_OUT}/ThreadPool.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/agent/threads/ThreadPool.cpp

${AGENT_OUT}/WorkerThread.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/agent/threads/WorkerThread.cpp
	
${AGENT_OUT}/Bucket.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/agent/Bucket.cpp

${AGENT_OUT}/BucketList.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/agent/BucketList.cpp

${AGENT_OUT}/SystemReceiver.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/agent/SystemReceiver.cpp
	
${AGENT_OUT}/ConnectorManager.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/connector/ConnectorManager.cpp
	
${AGENT_OUT}/Plugin.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/Plugin.cpp

${AGENT_OUT}/ConfigurationConnector.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/connector/configuration/ConfigurationConnector.cpp

${CONNECTOR_OUT}/OStreamConnector.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/connector/ostream/OStreamConnector.cpp
	
${COMMON_OUT}/FileUtils.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/util/FileUtils.cpp
	
${COMMON_OUT}/LibraryUtils.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/util/LibraryUtils.cpp
	
${COMMON_OUT}/Logger.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/Logger.cpp

${COMMON_OUT}/LogManager.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/LogManager.cpp

${COMMON_OUT}/Thread.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/port/${PORTDIR}/Thread.cpp

${COMMON_OUT}/Lock.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/port/Lock.cpp

${COMMON_OUT}/Process.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/port/${PORTDIR}/Process.cpp
	
${COMMON_OUT}/ThreadData.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/port/ThreadData.cpp
	
${COMMON_OUT}/Properties.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/Properties.cpp
	
${COMMON_OUT}/PropertiesFile.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/PropertiesFile.cpp
	
${COMMON_OUT}/memUtils.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/util/memUtils.cpp
	
${COMMON_OUT}/MemoryManager.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/MemoryManager.cpp
	
${COMMON_OUT}/strUtils.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/util/strUtils.cpp
	
${COMMON_OUT}/sysUtils.o: 
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/common/util/sysUtils.cpp
	
${PLUGIN_OUT}/envplugin.o: ${OMR-AGENTCORE_SRC}/monitoring/plugins/common/environment/envplugin.cpp
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/plugins/common/environment/envplugin.cpp
	
${PLUGIN_OUT}/cpuplugin.o: ${OMR-AGENTCORE_SRC}/monitoring/plugins/common/cpu/cpuplugin.cpp
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/plugins/common/cpu/cpuplugin.cpp

${PLUGIN_OUT}/MemoryPlugin.o: ${OMR-AGENTCORE_SRC}/monitoring/plugins/common/memory/MemoryPlugin.cpp
	${CC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/plugins/common/memory/MemoryPlugin.cpp	
	
	

#---------------
# MQTT Connector
#---------------
#${CONNECTOR_OUT}/MQTTConnector.o: HC_EXPORT=
${CONNECTOR_OUT}/MQTTConnector.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/connector/mqtt/MQTTConnector.cpp

#---------------
# API Connector
#---------------
${CONNECTOR_OUT}/APIConnector.o: 
	${GCC} ${AGENTCORE-INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${OMR-AGENTCORE_SRC}/monitoring/connector/api/APIConnector.cpp



#----------------------
# PAHO MQTT client code
#----------------------
${PAHO_OUT}/Clients.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/Clients.c
	
${PAHO_OUT}/Heap.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/Heap.c
	 
${PAHO_OUT}/LinkedList.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/LinkedList.c
	 
${PAHO_OUT}/Log.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/Log.c
	 
${PAHO_OUT}/Messages.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/Messages.c
	 
${PAHO_OUT}/MQTTAsync.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/MQTTAsync.c
	 
${PAHO_OUT}/MQTTPacket.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/MQTTPacket.c
	 
${PAHO_OUT}/MQTTPacketOut.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/MQTTPacketOut.c
	 
${PAHO_OUT}/MQTTPersistence.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/MQTTPersistence.c
	 
${PAHO_OUT}/MQTTPersistenceDefault.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/MQTTPersistenceDefault.c
	 
${PAHO_OUT}/MQTTProtocolClient.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/MQTTProtocolClient.c
	 
${PAHO_OUT}/MQTTProtocolOut.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/MQTTProtocolOut.c
	 
${PAHO_OUT}/SocketBuffer.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/SocketBuffer.c
	 
${PAHO_OUT}/Socket.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/Socket.c
	 
${PAHO_OUT}/StackTrace.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/StackTrace.c
	 
${PAHO_OUT}/Thread.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/Thread.c
	 
${PAHO_OUT}/Tree.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/Tree.c
	 
${PAHO_OUT}/utf-8.o: 
	${GCC} ${AGENTCORE-INCS} ${MQTT_INCS} ${CFLAGS} -D${PLATFORM} ${OBJOPT} ${PAHO_SRC}/utf-8.c
	



#-------------------------------------------------------------------------------------------
#Various install destinations
#-------------------------------------------------------------------------------------------
setup: ${OUTPUT}
	
${OUTPUT}:
	@echo "Creating required build directories under ${OUTPUT}"
	mkdir -p ${OUTPUT}
	mkdir -p ${CONNECTOR_OUT}
	mkdir -p ${AGENT_OUT}
	mkdir -p ${COMMON_OUT}
	mkdir -p ${PLUGIN_OUT}
	mkdir -p ${OMR_OUT}
	mkdir -p ${PAHO_OUT}

clean: 
	rm -fr ${OUTPUT}

coreinstall: core
	@echo "installing to  ${INSTALL_DIR}"
	mkdir -p ${INSTALL_DIR}/plugins
	mkdir -p ${INSTALL_DIR}/libs
	${COPY_CONNECTOR}
	cp src/properties/healthcenter.properties ${INSTALL_DIR}
	cp ${OMR_OUT}/${LIB_PREFIX}agentcore.${LIB_EXT} ${INSTALL_DIR}
	cp ${PLUGIN_OUT}/*.${LIB_EXT} ${INSTALL_DIR}/plugins
	@echo "-----------------------------------------------------------------------------------------------------------------------"
             
