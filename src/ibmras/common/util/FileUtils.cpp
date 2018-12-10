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

#if defined(_ZOS)
#define _UNIX03_SOURCE
#endif

#include "ibmras/common/util/FileUtils.h"
#include "ibmras/common/logging.h"

#if defined(WINDOWS)
#include <windows.h>
#include <tchar.h>
#else
#include <dlfcn.h>
#include <sys/stat.h>
#include <errno.h>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#endif

#define BASEFILEPERM (S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH)
#define BASEDIRPERM (S_IRWXU|S_IRWXG|S_IROTH|S_IXOTH)

namespace ibmras {
namespace common {
namespace util {

IBMRAS_DEFINE_LOGGER("FileUtils");

bool createDirectory(std::string& path) {
	IBMRAS_DEBUG(debug, ">>>FileUtils::createDirectory");
	bool created = false;

	const char* pathName = path.c_str();

#if defined(WINDOWS)
	DWORD dirAttr;
	dirAttr = GetFileAttributes(reinterpret_cast<LPCTSTR>(pathName));

	if(INVALID_FILE_ATTRIBUTES == dirAttr) {
		switch (GetLastError()) {
			case ERROR_PATH_NOT_FOUND:
				IBMRAS_DEBUG_1(fine, "Directory %s was not found - creating", pathName);
				if(!CreateDirectory(reinterpret_cast<LPCTSTR>(pathName), NULL)) {
					switch (GetLastError()) {
						//if the directory already exists we will use it instead of the current one.
						case ERROR_ALREADY_EXISTS:
							IBMRAS_DEBUG_1(fine, "Directory %s already exists.", pathName);
							created = true;
							break;
						case ERROR_PATH_NOT_FOUND:
							IBMRAS_DEBUG(warning, "The system cannot find the path specified.");
							break;
					}
				} else {
                    IBMRAS_DEBUG_1(debug, "Directory %s created.", pathName);
					created = true;
				}
				break;
			case ERROR_INVALID_NAME:
			IBMRAS_DEBUG(warning, "The filename, directory name, or volume label syntax is incorrect");
			break;
			case ERROR_BAD_NETPATH:
			IBMRAS_DEBUG(warning, "The network path was not found.");
			break;
			default:
			IBMRAS_DEBUG_1(fine, "Directory %s could not be found, permissions? Attempting creation.", pathName);
			if(!CreateDirectory(reinterpret_cast<LPCTSTR>(pathName), NULL)) {
				switch (GetLastError()) {
					case ERROR_ALREADY_EXISTS:
					IBMRAS_DEBUG_1(fine, "Directory %s already exists.", pathName);
					created = true;
					break;
					case ERROR_PATH_NOT_FOUND:
					IBMRAS_DEBUG(warning, "The system cannot find the path specified.");
					break;
				}
			} else {
                IBMRAS_DEBUG_1(debug, "Directory %s created.", pathName);
				created = true;
			}
		}
	} else {
        IBMRAS_DEBUG_1(debug, "Directory %s already exists", pathName);
        created = true;
    }

#else
	struct stat dir;
	IBMRAS_DEBUG_1(debug, "Pathname = %s", pathName);
	if (stat(pathName, &dir)) {
		IBMRAS_DEBUG_1(fine, "Directory %s does not exist. Attempting creation", pathName);
		if (-1 == mkdir(pathName, BASEDIRPERM)) {
			if(EEXIST == errno) {
				IBMRAS_DEBUG_1(debug, "Directory % already existed", pathName);
				created = true;
			} else {
                IBMRAS_DEBUG_2(warning, "Directory %s could not be created: %s", pathName, strerror(errno));
            }
		} else {
			IBMRAS_DEBUG_1(debug, "Directory %s was created", pathName);
            chmod(pathName,BASEDIRPERM);
			created = true;
		}
	} else {
		IBMRAS_DEBUG_1(fine, "stat() returned 0, checking whether %s is an existing directory", pathName);
		if(S_ISDIR(dir.st_mode)) {
            IBMRAS_DEBUG_1(debug, "Directory %s does exist", pathName);
			created = true;
		}
	}
#endif
	IBMRAS_DEBUG(debug, "<<<FileUtils::createDirectory()");

	return created;
}

bool createFile(std::string& path) {
	bool created = false;
    const char* pathName = path.c_str();
    IBMRAS_DEBUG_1(debug, ">>>FileUtils::createFile(), path = %s", pathName);

#if defined(WINDOWS)
    HANDLE fileHandle;
	DWORD fileAttr;
	fileAttr = GetFileAttributes(reinterpret_cast<LPCTSTR>(pathName));

	if(INVALID_FILE_ATTRIBUTES == fileAttr) {
		switch (GetLastError()) {
			case ERROR_PATH_NOT_FOUND:
				IBMRAS_DEBUG_1(fine, "File %s was not found. Attempting to create.", pathName);
				fileHandle = CreateFile(reinterpret_cast<LPCTSTR>(pathName), (GENERIC_READ | GENERIC_WRITE), (FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE), NULL, CREATE_NEW, FILE_ATTRIBUTE_HIDDEN, NULL);
				if(INVALID_HANDLE_VALUE == fileHandle) {
					switch (GetLastError()) {
						//if the directory already exists we will use it instead of the current one.
						case ERROR_FILE_EXISTS:
							IBMRAS_DEBUG_1(warning, "File %s already exists.", pathName);
							created = true;
							break;
						case ERROR_PATH_NOT_FOUND:
							IBMRAS_DEBUG_1(warning, "The system cannot find file %s.", pathName);
							break;
					}
				} else {
					created = true;
                    CloseHandle(fileHandle);
				}
				break;
			case ERROR_INVALID_NAME:
			IBMRAS_DEBUG(warning, "The filename, directory name, or volume label syntax is incorrect");
			break;
			case ERROR_BAD_NETPATH:
			IBMRAS_DEBUG(warning, "The network path was not found.");
			break;
			default:
			IBMRAS_DEBUG_1(fine, "File %s could not be found, permissions? Attempting to create", pathName);
			fileHandle = CreateFile(reinterpret_cast<LPCTSTR>(pathName), (GENERIC_READ | GENERIC_WRITE), (FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE), NULL, CREATE_NEW, FILE_ATTRIBUTE_HIDDEN, NULL);
			if(INVALID_HANDLE_VALUE == fileHandle) {
				switch (GetLastError()) {
					case ERROR_FILE_EXISTS:
					IBMRAS_DEBUG_1(fine, "File %s already exists.", pathName);
					created = true;
					break;
					case ERROR_PATH_NOT_FOUND:
					IBMRAS_DEBUG_1(warning, "The system cannot find file %s.", pathName);
					break;
				}
			} else {
				created = true;
                CloseHandle(fileHandle);
			}
		}
	}

#else
	struct stat file;
    int fd;
	if (stat(pathName, &file)) {
		IBMRAS_DEBUG_1(debug, "File %s does not exist, attempting creation", pathName);
        fd = open(pathName, (O_CREAT|O_EXCL|O_WRONLY), BASEFILEPERM);
		if (-1 == fd) {
			if(EEXIST == errno) {
				IBMRAS_DEBUG_1(debug, "File %s already exists", pathName);
				created = true;
			} else {
                IBMRAS_DEBUG_2(debug, "File %s could not be created: %s", pathName, strerror(errno));
            }
		} else {
			IBMRAS_DEBUG_1(debug, "File %s was created", pathName);
            close(fd);
            chmod(pathName, BASEFILEPERM);
			created = true;
		}
	} else {
		IBMRAS_DEBUG_1(debug, "stat() returned 0, checking whether %s is an existing file", pathName);
		if(S_ISDIR(file.st_mode)) {
            IBMRAS_DEBUG_1(warning, "File could not be created: %s is a directory", pathName);
		} else {
            IBMRAS_DEBUG_1(debug, "File %s does exist", pathName);
            created = true;
        }
	}
#endif

    IBMRAS_DEBUG(debug, "<<<FileUtils::createfile()");
	return created;
}


}//util
}//common
}//ibmras
