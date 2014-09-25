#
# =BEGIN MIT LICENSE
# 
# The MIT License (MIT)
#
# Copyright (c) 2014 The CrossBridge Team
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# =END MIT LICENSE
#

.PHONY: debug clean all 

# Detect host 
$?UNAME=$(shell uname -s)
#$(info $(UNAME))
ifneq (,$(findstring CYGWIN,$(UNAME)))
	$?nativepath=$(shell cygpath -at mixed $(1))
	$?unixpath=$(shell cygpath -at unix $(1))
else
	$?nativepath=$(abspath $(1))
	$?unixpath=$(abspath $(1))
endif

# CrossBridge SDK Home
ifneq "$(wildcard $(call unixpath,$(FLASCC_ROOT)/sdk))" ""
 $?FLASCC:=$(call unixpath,$(FLASCC_ROOT)/sdk)
else
 $?FLASCC:=/path/to/crossbridge-sdk/
endif
$?ASC2=java -jar $(call nativepath,$(FLASCC)/usr/lib/asc2.jar) -merge -md -parallel
 
# Auto Detect AIR/Flex SDKs
ifneq "$(wildcard $(AIR_HOME)/lib/compiler.jar)" ""
 $?FLEX=$(AIR_HOME)
else
 $?FLEX:=/path/to/adobe-air-sdk/
endif

# C/CPP Compiler
$?BASE_CFLAGS=-Werror -Wno-write-strings -Wno-trigraphs
$?EXTRACFLAGS=
$?OPT_CFLAGS=-O4

# ====================================================================================
# HOST PLATFORM OPTIONS
# ====================================================================================
# Windows or OSX or Linux
ifneq (,$(findstring CYGWIN,$(UNAME)))
$?BUILD_TRIPLE=i686-pc-cygwin
else ifneq (,$(findstring Darwin,$(UNAME)))
$?BUILD_TRIPLE=x86_64-apple-darwin10
else
$?BUILD_TRIPLE=x86_64-unknown-linux-gnu
endif
$?TRIPLE=avm2-unknown-freebsd8

all: obj swc swf

obj: 
	mkdir -p build
	mkdir -p install
	cp -r DevIL/* build/
	cd build && autoreconf -i
	cd build && PATH="$(call unixpath,$(FLASCC)/usr/bin):/usr/bin/:/usr/local/bin/" CC=$(CC) CXX=$(CXX) configure --disable-shared --enable-static --prefix=install --build=$(BUILD_TRIPLE) --host=$(TRIPLE) --target=$(TRIPLE)
	cd build && PATH="$(call unixpath,$(FLASCC)/usr/bin):/usr/bin/:/usr/local/bin/" make install

swc: 
	ls

swf: 
	#$(FLEX)/bin/mxmlc -library-path+=release/crossbridge-devil.swc src/main/actionscript/Main.as -debug=false -o build/Main.swf

clean:
	rm -rf build install
