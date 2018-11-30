/*******************************************************************************
 * Copyright 2017 IBM Corp.
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

/*
 * Functions that control thread behaviour
 */

#pragma longname
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE
#endif
#define _XOPEN_SOURCE_EXTENDED 1
#ifndef _UNIX03_THREADS
#define _UNIX03_THREADS
#endif
#define _OPEN_SYS
#define _OPEN_SYS_TIMED_EXT 1
#include <pthread.h>
#include <sys/types.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <sys/sem.h>
#include <sys/ipc.h>
#include <sys/modes.h>
#include <limits.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>

#include "ibmras/common/port/ThreadData.h"
#include "ibmras/common/port/Semaphore.h"
#include "ibmras/common/logging.h"
#include "ibmras/common/util/FileUtils.h"
#include "ibmras/monitoring/agent/Agent.h"

namespace ibmras {
namespace common {
namespace port {

#define SEM_STORE_DIR ".com_ibm_tools_hc"
#define SEM_SUFFIX "_notifier"
#define SEMFLAGS_OPEN (S_IRUSR | S_IWUSR)
#define SEMFLAGS_CREATE (IPC_CREAT | IPC_EXCL | S_IRUSR | S_IWUSR)
#define SEM_CREATED 1
#define SEM_OPENED 2
#define SEM_OPEN_FAILED 0
#define FILE_SEPARATOR "/"

IBMRAS_DEFINE_LOGGER("Port");

extern "C" void* wrapper(void *params) {
	IBMRAS_DEBUG(fine,"in thread.cpp->wrapper");
	ThreadData* data = reinterpret_cast<ThreadData*>(params);
	return data->getCallback()(data);
}

uintptr_t createThread(ThreadData* data) {
	IBMRAS_DEBUG(fine,"in thread.cpp->createThread");
	pthread_t thread;
	return pthread_create(&thread, NULL, wrapper, data);
}

void exitThread(void *val) {
	IBMRAS_DEBUG(fine,"in thread.cpp->exitThread");
	pthread_exit(NULL);
}

void sleep(uint32 seconds) {
	IBMRAS_DEBUG(fine,"in thread.cpp->sleep");
	::sleep(seconds); /* configure the sleep interval */
}

void stopAllThreads() {
	IBMRAS_DEBUG(fine,"in thread.cpp->stopAllThreads");
}

int key_increment = 0;

int initsem(int nsems) {
	int semid = -1;

	time_t seconds;
	seconds = time(NULL);
	key_t key = seconds;

	// Retry until we can get a unique semaphore.
	for (int i = 1; i < 100; i++) {
		IBMRAS_DEBUG_1(debug, "getting semaphore for key %d", (int)key);
		semid = semget(key, nsems, IPC_CREAT | IPC_EXCL | 0666);
		if (semid == -1 && errno == EEXIST) {

			IBMRAS_DEBUG_1(debug, "semaphore for key %d already exists, retrying", (int)key);
			key = key - 1;
		} else {
			break;
		}
	}

	return semid;
}

int sem_initialize(int *semid, int value) {
	int ret = semctl(*semid, 0, SETVAL, value);
	return ret;
}

int sem_init(int *sem, int pshared, unsigned int value) {
	int ret = -1;
	if (value > INT_MAX) {
		errno = EINVAL;
		return ret;
	}
	if ((*sem = initsem(1)) == -1) {
		return -1;
	} else
		ret = sem_initialize(sem, value);
	if (ret == -1) {
		return -1;
	}
	return ret;
}

int sem_destroy(int *semid) {
	int ret = semctl(*semid, 0, IPC_RMID);
	if (ret == -1) {
		return -1;
	}
	return ret;
}

int sem_post(int *semid) {
	struct sembuf sb;
	sb.sem_num = 0;
	sb.sem_op = 1;
	sb.sem_flg = 0;
	if (semop(*semid, &sb, 1) == -1) {
		return -1;
	}
	return 0;
}

int sem_wait(int *semid) {
	struct sembuf sb;
	sb.sem_num = 0;
	sb.sem_op = -1;
	sb.sem_flg = 0;
	if (semop(*semid, &sb, 1) == -1) {
		return -1;
	}
	return 0;
}

int sem_timedwait(int *semid, struct timespec *t) {
	struct sembuf sb;
	sb.sem_num = 0;
	sb.sem_op = -1;
	sb.sem_flg = 0;
	if (__semop_timed(*semid, &sb, 1, t) == -1) {
		return -1;
	}
	return 0;
}

bool getIPCKey(key_t* handle, std::string name) {
    // get the semaphore temp dir set in the loader
    std::string tempDir = ibmras::monitoring::agent::Agent::getInstance()->getProperty("platform_tempdir");
    if ("" == tempDir) {
        IBMRAS_DEBUG(debug, "Defaulting tempDir to /tmp");
        tempDir = "/tmp";
    }
    std::string semRecDir = tempDir + FILE_SEPARATOR + SEM_STORE_DIR;
    // Create the semaphore resource directory if it doesn't exist
    int directoryExists = ibmras::common::util::createDirectory(semRecDir);
    IBMRAS_DEBUG_2(debug,"ibmras::common::util::createDirectory(%s) = %d", semRecDir.c_str(), directoryExists);
    if (directoryExists) {
        std::string baseFile = semRecDir + FILE_SEPARATOR + name + SEM_SUFFIX;
        IBMRAS_DEBUG_1(debug, "baseFile = %s", baseFile.c_str());
        int fileExists = ibmras::common::util::createFile(baseFile);
        IBMRAS_DEBUG_2(debug,"ibmras::common::util::createFile(%s) = %d", baseFile.c_str(), fileExists);
        if (fileExists) {
            uint8_t hc_id = 0x8c; // unique prefix to identify semaphore IDs as Health Centerol
            /* Generate the key for creating the semaphore*/
            *handle = ftok(baseFile.c_str(), hc_id);
            IBMRAS_DEBUG_2(info, "IPCkey for %s is %x", baseFile.c_str(), *handle);
            if (-1 == *handle) {
                IBMRAS_LOG_1(warning, "Unable to obtain semaphore IPC key: %s", strerror(errno));
                return false;
            } else {
                return true;
            }
        } else {
            IBMRAS_LOG_1(warning, "Failed to create file %s; semaphore key not created", baseFile.c_str());
        return false;
        }
    } else {
        IBMRAS_LOG_1(warning, "Failed to create directory %s; semaphore key not created", semRecDir.c_str());
        return false;
    }
}

Semaphore::Semaphore(uint32 initial, uint32 max, const char* sourceName) {
    name = sourceName;
    // handle will store the IPC key needed to open a semaphore
    handle = new key_t*;
    if (!getIPCKey((reinterpret_cast<key_t*>(handle)), name)) {
        handle = NULL;
    }
}

int Semaphore::open(int* semid) {
	IBMRAS_DEBUG_1(fine,"in thread.cpp creating semaphore for source %s", name.c_str());
    if (handle) {
        int semflags_create;
        int semflags_open;
        uint32 permissions = 0666;
        /* trim the permissions down to 9 least significant bits */
        permissions &= 0777;
        semflags_open = SEMFLAGS_OPEN | permissions;
        semflags_create = SEMFLAGS_CREATE | permissions;
        // attempt to create semaphore
        *semid = semget(*(reinterpret_cast<key_t*>(handle)), 1, semflags_create);
        if (-1 == *semid) {
            if (EEXIST == errno) {
                IBMRAS_DEBUG(debug, "Semaphore already exists; attempt to open");
                *semid = semget(*(reinterpret_cast<key_t*>(handle)), 1, semflags_open);
            }
            if (-1 == *semid) {
                IBMRAS_LOG_1(warning, "Unable to obtain semaphore: ", strerror(errno));
                return SEM_OPEN_FAILED;
            } else {
                IBMRAS_DEBUG_1(debug, "Semaphore %d opened", *semid);
                return SEM_OPENED;
            }
        } else {
            IBMRAS_DEBUG_1(debug, "Semaphore %d created", *semid);
            return SEM_CREATED;
        }
    } else {
        IBMRAS_LOG(warning, "Unable to obtain semaphore: invalid key");
        // attempt to generate a new key for next time
        handle = new key_t*;
        if (!getIPCKey((reinterpret_cast<key_t*>(handle)), name)) {
            handle = NULL;
        }
        return SEM_OPEN_FAILED;
    }
}

void Semaphore::inc() {
    int semid;
    int result;
    result = Semaphore::open(&semid);
	if (result) {
        if (SEM_CREATED == result) {
            // shouldn't be incrementing a semaphore that doesn't already exist - probably shutting down
            sem_destroy(&semid);
        } else {
            IBMRAS_DEBUG_2(finest, "Incrementing semaphore %d (%s)", semid, name.c_str());
            sem_post(&semid);
        }
	}
}

bool Semaphore::wait(uint32 timeout) {
    int semid;
	int result;
	struct timespec t;

	result = Semaphore::open(&semid);
    if (result) {
        t.tv_sec = timeout; /* configure the sleep interval */
        t.tv_nsec = 0;
    
        result = sem_timedwait(&semid, &t);
        if (!result) {
            IBMRAS_DEBUG_2(finest, "Process %s waiting for semaphore %d", name.c_str(), semid);
            return true;
        } 
        IBMRAS_DEBUG_1(finest, "possible timeout for semaphore %d", semid);
        return (errno != EAGAIN);
    } else {
        IBMRAS_LOG_1(warning, "Unable to obtain semaphore to wait on: %s", strerror(errno));
        return false;
    }
}

Semaphore::~Semaphore() {
    int semid;
    int result;
    int n_count;
    int z_count;

    result = Semaphore::open(&semid);
    if (result) {
        // how many processes are waiting for the semaphore?
        n_count = semctl(semid, 0, GETNCNT);
        z_count = semctl(semid, 0, GETZCNT);
        if (-1 == n_count || -1 == z_count) {
            IBMRAS_LOG_1(warning, "Unable to access semaphore info: %s", strerror(errno));
        } else {
            // if we're the last semaphore users, no one should be waiting
            if (0 == (n_count + z_count)) {
                IBMRAS_DEBUG_2(debug, "Destroying semaphore %d for %s", semid, name.c_str());
                sem_destroy(&semid);
            }
        }
    }
	delete handle;
}

}
}
} /* end namespace port */
