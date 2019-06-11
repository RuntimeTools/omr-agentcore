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


#include "ibmras/common/util/strUtils.h"
#include "ibmras/common/MemoryManager.h"
#include <sstream>
#include "ibmras/common/Logger.h"
#include <cstring>
#include <stdlib.h>
#include <string>
#include <stdint.h>


#if defined(WINDOWS)
#include <windows.h>
#include <intrin.h>
#include <winbase.h>
#endif

#if defined(_ZOS)
#include <unistd.h>
#include <locale.h>
#include <iconv.h>
#endif

namespace ibmras {
namespace common {
namespace util {

std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        elems.push_back(item);
    }
    return elems;
}

std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> elems;
    split(s, delim, elems);
    return elems;
}

bool endsWith(const std::string& str, const std::string& suffix) {
	return (str.length() >= suffix.length() && (0 == str.compare(str.length() - suffix.length(), suffix.length(), suffix)));
}

bool startsWith(const std::string& str, const std::string& prefix) {
	return (str.length() >= prefix.length() && (0 == str.compare(0, prefix.length(), prefix)));
}


bool equalsIgnoreCase(const std::string& s1, const std::string& s2) {


	if (s1.length() != s2.length()) {
		return false;
	}

	for(std::string::size_type i = 0; i < s1.size(); ++i) {
	    if (toupper(s1[i]) !=  toupper(s2[i]) ) {
	    	return false;
	    }
	}

	return true;
}

#if defined(_ZOS)
std::string expectedNativeCodepage() {
  std::string localeString(setlocale(LC_ALL, NULL));
  std::size_t dotIndex = localeString.find_first_of('.');
  if (dotIndex != std::string::npos) {
    // might have additional @xxx or .xxx - remove)
    std::size_t atIndex = localeString.find_first_of("@.", dotIndex + 1);
    // this will be either where an @ sign is or npos
    if (dotIndex != std::string::npos) {
      return localeString.substr(dotIndex + 1, atIndex - dotIndex - 1);
    } else {
      return localeString.substr(dotIndex + 1);
    }
  } else {
    return "IBM-1047";
  }
}


int convertCodePage(char * str, const char* toCodePage, const char * fromCodePage) {
  // return 0: no change, 1: changed, -1: error
  std::string codepage = expectedNativeCodepage();
  if (codepage.compare("IBM-1047") == 0) {
      //already in that codepage - return
      return 0;
  }
  char *cp = (char*)ibmras::common::memory::allocate(strlen(str) + 1);
  strcpy(cp,str);
  iconv_t cd;
  size_t rc;
  char *inptr = cp;
  char *outptr = str;
  size_t inleft = strlen(str);
  size_t outleft = strlen(str);

  if ((cd = iconv_open(toCodePage, fromCodePage)) == (iconv_t)(-1)) {
    fprintf(stderr, "Cannot open converter to %s from %s\n", toCodePage, fromCodePage);
    return -1;
  }

  rc = iconv(cd, &inptr, &inleft, &outptr, &outleft);
  if (rc == -1) {
    fprintf(stderr, "Error in converting characters\n");
  }
  else {
    rc = 1;
  }
  iconv_close(cd);
  ibmras::common::memory::deallocate((unsigned char**)&cp);
  return rc;
}
#endif


void native2Ascii(char * str, bool convertToCurrentLocale) {
#if defined(_ZOS)
    if ( NULL != str )
    {
        if (convertToCurrentLocale) {
          int rc = convertCodePage(str, expectedNativeCodepage().c_str(), "IBM-1047");
          if (rc==1) { 
            __etoa(str);
          }
        }
    }
#endif
}


/******************************/
void
ascii2Native(char * str, bool convertFromCurrentLocale)
{
#if defined(_ZOS)
    if ( NULL != str )
    {
        __atoe(str);
        if (convertFromCurrentLocale) {
          convertCodePage(str, "IBM-1047", expectedNativeCodepage().c_str());
        }
    }
#endif

}


/******************************/
void
force2Native(char * str)
{
#ifdef _ZOS
	char *p = str;

    if ( NULL != str )
    {
        while ( 0 != *p )
        {
            if ( 0 != ( 0x80 & *p ) )
            {
                p = NULL;
                break;
            }
            p++;
        }

        if ( NULL != p )
        {
            __atoe(str);
        }
    }
#endif
}

char* createAsciiString(const char* nativeString, bool convertToCurrentLocale) {
    char* cp = NULL;
    if ( NULL != nativeString )
    {
        cp = (char*)ibmras::common::memory::allocate(strlen(nativeString) + 1);
        if ( NULL == cp )
        {
            return NULL;
        } else
        {
            /* jnm is valid, so is cp */
            strcpy(cp,nativeString);
            native2Ascii(cp, convertToCurrentLocale);
        }
    }
    return cp;
}

char* createNativeString(const char* asciiString, bool convertFromCurrentLocale) {
    char* cp = NULL;
    if ( NULL != asciiString )
    {
        cp = (char*)ibmras::common::memory::allocate(strlen(asciiString) + 1);
        if ( NULL == cp )
        {
            return NULL;
        } else
        {
            /* jnm is valid, so is cp */
            strcpy(cp,asciiString);
            ascii2Native(cp, convertFromCurrentLocale);
        }
    }
    return cp;
}


}/*end of namespace util*/
}/*end of namespace common*/
} /*end of namespace ibmras*/
