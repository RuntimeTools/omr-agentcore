 /**
 * IBM Confidential
 * OCO Source Materials
 * IBM Monitoring and Diagnostic Tools - Health Center
 * (C) Copyright IBM Corp. 2007, 2015 All Rights Reserved.
 * The source code for this program is not published or otherwise
 * divested of its trade secrets, irrespective of what has
 * been deposited with the U.S. Copyright Office.
 */


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


void convertCodePage(char * str, const char* toCodePage, const char * fromCodePage) {
  std::string codepage = expectedNativeCodepage();
  if (codepage.compare("IBM-1047") == 0) {
      //already in that codepage - return
      return;
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
    return;
  }

  rc = iconv(cd, &inptr, &inleft, &outptr, &outleft);
  if (rc == -1) {
    fprintf(stderr, "Error in converting characters\n");
  }
  iconv_close(cd);
  ibmras::common::memory::deallocate((unsigned char**)&cp);
}
#endif


void native2Ascii(char * str, bool convertToCurrentLocale) {
#if defined(_ZOS)
    if ( NULL != str )
    {
        if (convertToCurrentLocale) {
          convertCodePage(str, expectedNativeCodepage().c_str(), "IBM-1047");
        }
        __etoa(str);
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
