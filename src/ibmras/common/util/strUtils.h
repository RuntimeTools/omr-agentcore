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


#include <string>
#include <vector>
#include "ibmras/monitoring/AgentExtensions.h"

#ifndef STRUTILS_H_
#define STRUTILS_H_

namespace ibmras {
namespace common {
namespace util {

std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems);
std::vector<std::string> split(const std::string &s, char delim);
bool endsWith(const std::string& str, const std::string& suffix);
bool startsWith(const std::string& str, const std::string& prefix);
DECL bool equalsIgnoreCase(const std::string& s1, const std::string& s2);
DECL void native2Ascii(char * str, bool convertToCurrentLocale = true);
DECL void ascii2Native(char * str, bool convertFromCurrentLocale = true);
DECL void force2Native(char * str);
DECL char* createAsciiString(const char* nativeString, bool convertToCurrentLocale = true);
DECL char* createNativeString(const char* asciiString, bool convertFromCurrentLocale = true);

}/*end of namespace util*/
}/*end of namespace common*/
} /*end of namespace ibmras*/




#endif /* STRUTILS_H_ */
