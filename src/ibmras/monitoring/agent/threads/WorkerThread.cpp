/*******************************************************************************
 * Copyright 2016 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *******************************************************************************/


#include "ibmras/monitoring/agent/threads/WorkerThread.h"
#include "ibmras/monitoring/agent/Agent.h"
#include "ibmras/common/logging.h"

namespace ibmras {
namespace monitoring {
namespace agent {
namespace threads {

extern IBMRAS_DECLARE_LOGGER;


WorkerThread::WorkerThread(pullsource* pullSource) : semaphore(0, 1, pullSource->header.name), data(threadEntry, cleanUp), countdown(0) {
	source = pullSource;
	running = false;
	stopped = true;
	data.setArgs(this);
}


void WorkerThread::start() {
	IBMRAS_DEBUG_1(fine, "Starting worker thread for %s", source->header.name);
	running = true;
	stopped = false;
	ibmras::common::port::createThread(&data);
}

void WorkerThread::stop() {
	// Issue 102: By completing pull sources too early might
	// intermittenlty destruct while still in processLoop.
	#if !defined(_WINDOWS) && !defined(_ZOS)
		source->complete(NULL);
	#endif
	running = false;

	// Issue 99: By setting stopped to true too early, ThreadPool
	// might intermittently destruct us while we're still in processLoop.
	// We've already set running=false, so processLoop will finish the
	// next chance it gets and only then will set stopped=true.
	//stopped = true;

	semaphore.inc();
	IBMRAS_DEBUG_1(debug, "Worker thread for %s stopping", source->header.name);
}

void* WorkerThread::cleanUp(ibmras::common::port::ThreadData* data) {
	((WorkerThread*) data->getArgs())->stop();
	return NULL;
}

void* WorkerThread::threadEntry(ibmras::common::port::ThreadData* data) {
	((WorkerThread*) data->getArgs())->processLoop();
	ibmras::common::port::exitThread(NULL);
	return NULL;
}

void WorkerThread::process(bool immediate) {
    IBMRAS_DEBUG_2(finest, "Worker thread process for %s, countdown is %d", source->header.name, countdown);
	if ((immediate && countdown > 120) || (countdown == 0)) {
		semaphore.inc();
		countdown = source->pullInterval;
	} else {
		countdown--;
	}
}

bool WorkerThread::isStopped() {
	return stopped;
}

void* WorkerThread::processLoop() {
	IBMRAS_DEBUG_1(finest, "Worker thread started for %s", source->header.name);
	Agent* agent = Agent::getInstance();
	while (running) {
		if (semaphore.wait(1) && running) {
			IBMRAS_DEBUG_1(fine, "Pulling data from source %s", source->header.name);
			monitordata* data = source->callback();
			if (data != NULL) {
				if (data->size > 0) {
					IBMRAS_DEBUG_2(finest, "%d bytes of data pulled from source %s", data->size, source->header.name);
					agent->addData(data); /* put pulled data on queue for processing */
				}
				source->complete(data);
			}
		}
	}

	source->complete(NULL);
	stopped = true;
	IBMRAS_DEBUG_1(finest, "Worker thread for %s exiting process loop", source->header.name);
	return NULL;
}


}
}
}
} /* end of namespace threads */
