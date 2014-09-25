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
$?CCOMPARGS=-Werror -Wno-write-strings -Wno-trigraphs -O4 -I./install/include 

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

all: init lib swig abc obj swc swf

# Init build
init: 
	mkdir -p temp
	mkdir -p build
	mkdir -p install

# Generate Library
lib: 
	cp -r DevIL/* build/
	cd build && PATH="$(call unixpath,$(FLASCC)/usr/bin):$(PATH)" CC=$(CC) CXX=$(CXX) ./configure \
	--prefix=$(PWD)/install --build=$(BUILD_TRIPLE) --host=$(TRIPLE) --target=$(TRIPLE) \
	--enable-sse=no --enable-sse2=no --enable-sse3=no --enable-altivec=no --disable-asm --enable-static=yes --enable-shared=no --disable-dependency-tracking 
	cd build && PATH="$(call unixpath,$(FLASCC)/usr/bin):$(PATH)" make install

# Generate SWIG wrapper (AS3<>C)
swig: 
	"$(FLASCC)/usr/bin/swig" -I./. -I./install/include -as3 -module ClientLib -outdir . -includeall -ignoremissing -o ClientLib_wrapper.c $(PWD)/as3api.h

# Generate ABC ByteCode
abc:
	@echo "-------------------------------------------- ABC --------------------------------------------"
	$(ASC2) -abcfuture -AS3 \
				-import $(call nativepath,$(FLASCC)/usr/lib/builtin.abc) \
				-import $(call nativepath,$(FLASCC)/usr/lib/playerglobal.abc) \
				ClientLib.as
	mv ClientLib.as temp/ClientLib.as
	mv ClientLib.abc temp/ClientLib.abc

# Generate linker OBJ   
obj:
	@echo "-------------------------------------------- OBJ --------------------------------------------"
	"$(FLASCC)/usr/bin/gcc" $(CCOMPARGS) -c ClientLib_wrapper.c -o temp/ClientLib_wrapper.o
	cp -f exports.txt temp/ 
	"$(FLASCC)/usr/bin/nm" temp/ClientLib_wrapper.o | grep ' T ' | sed 's/.*__/_/' | sed 's/.* T //' >> temp/exports.txt
 
# Generate library SWC 
swc:
	@echo "-------------------------------------------- SWC --------------------------------------------"
	"$(FLASCC)/usr/bin/gcc" $(CCOMPARGS) temp/ClientLib.abc \
        ClientLib_wrapper.c \
        ClientLib.h \
        ClientLib.c \
        -flto-api=temp/exports.txt -swf-version=26 -emit-swc=crossbridge.DevIL -o release/crossbridge-devil.swc
	mv ClientLib_wrapper.c temp/ClientLib_wrapper.c

# Generate test SWF
swf:
	@echo "-------------------------------------------- SWF --------------------------------------------"
	"$(FLEX)/bin/mxmlc" -advanced-telemetry -swf-version=26 -library-path+=release/crossbridge-devil.swc src/main/actionscript/Main.as -debug=false -optimize -remove-dead-code -o build/Main.swf

# Generate build folders
clean:
	rm -rf build install temp
