# Copyright 2017 by Avnera Corporation, Beaverton, Oregon.
#
# All Rights Reserved
#
# This file may not be modified, copied, or distributed in part or in whole
# without prior written consent from Avnera Corporation.
#
# AVNERA DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
# ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
# AVNERA BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
# ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
# ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
# SOFTWARE.

.PHONY : default all Makefile

default : all

TOPDIR := $(CURDIR)
export TOPDIR

TOPBLD := $(shell $(TOPDIR)/etc/getTOPBLD.sh)
export TOPBLD

ADDED_CFLAGS :=
DEFINES :=

CHIP_REV = $(notdir $(CURDIR))
export CHIP_REV

ifndef VERBOSE
A = @
NOPRINTOPTION = --no-print-directory
endif # VERBOSE
export A

################################################################################
# Prerequisite directories - must be built first.

# For specific builds to populate to create custom bld dirs
BLD_SUFFIX = 

# MAC CPU targets
PREREQS = lib
SDK = sdk

# APP CPU targets
APPCPU_SUFFIX = _appcpu
APPCPU_PREREQS = lib$(APPCPU_SUFFIX)
APPCPU_SDK = sdk$(APPCPU_SUFFIX)

# default to no subdirectories
SUBDIRS ?=

ALLTARGETS = $(PREREQS) $(SDK) $(SUBDIRS)

ifneq (,$(filter dual, $(MAKECMDGOALS)))
ALLTARGETS += $(APPCPU_PREREQS) $(APPCPU_SDK)
BLD_SUFFIX = $(APPCPU_SUFFIX)
endif

ifneq (,$(filter clean realclean,$(MAKECMDGOALS)))
ALLTARGETS += $(APPCPU_PREREQS) $(APPCPU_SDK)
endif

ifneq (,$(filter rom,$(MAKECMDGOALS) $(REL_TARGET)))
ALLTARGETS += rom
DEFINES += -DROM_BUILD=1
DEFINES += -DSWHOOKS_EN=1
endif # rom

# RTOS define magic numbers (because Pre-processor can't handle strings).
RTOS ?= "none"

NONE = 0
MQX = 1
FREETOS = 2

ifeq ($(RTOS),"NONE")
override RTOS := $(NONE)
RTOSLIB =
endif # none
ifeq ($(RTOS),"none")
override RTOS := $(NONE)
RTOSLIB =
endif # none
ifeq ($(RTOS),"MQX")
override RTOS := $(MQX)
RTOSLIB = mqx
endif # mqx
ifeq ($(RTOS),"mqx")
override RTOS := $(MQX)
RTOSLIB = mqx
endif # mqx
ifeq ($(RTOS),"FREETOS")
override RTOS := $(FREETOS)
RTOSLIB = freetos
endif # freetos
ifeq ($(RTOS),"freetos")
override RTOS := $(FREETOS)
RTOSLIB = freetos
endif # freetos

export RTOSLIB
export DEFINES
export ADDED_CFLAGS
export MAKECMDGOALS

# DEFINES += -DRTOS=$(RTOS)
.PHONY: clean realclean $(ALLTARGETS)

.NOTPARALLEL: rom lib lib$(APPCPU_SUFFIX) release

# all: $(SUBDIRS)
all: sdk

$(PREREQS) :
	@echo "Building $@"
	$(A)$(MAKE) $(NOPRINTOPTION) -C $@

$(APPCPU_PREREQS) :
	@echo "Building $@"
	$(A)$(MAKE) $(NOPRINTOPTION) -C $(subst $(APPCPU_SUFFIX),,$@) APPCPU_BUILD=1 BLD_SUFFIX=$(BLD_SUFFIX)

rom : $(PREREQS)
	@echo "Building $@"
	$(A)$(MAKE) $(NOPRINTOPTION) -C $@

$(SDK) : $(PREREQS)
	@echo "Building $@"
	$(A)$(MAKE) $(NOPRINTOPTION) -C $@

$(APPCPU_SDK) :
	@echo "Building $@"
	$(A)$(MAKE) $(NOPRINTOPTION) -C $(subst $(APPCPU_SUFFIX),,$@) APPCPU_BUILD=1 BLD_SUFFIX=$(BLD_SUFFIX)

dual : $(APPCPU_PREREQS) $(PREREQS) $(SDK) $(APPCPU_SDK)

$(SUBDIRS) : $(SDK)
	@echo "Building $@"
	$(A)$(MAKE) $(NOPRINTOPTION) -C $@

romclean :
	@echo "Cleaning ROM build areas"
	$(A)rm -rf bld/rom

clean :
	@echo "Cleaning in `pwd`"
	$(A)for i in $(ALLTARGETS) \
	; do \
		target=$$(echo $$i | sed 's/$(APPCPU_SUFFIX)//'); \
		if [ "$$i" != "$$target" ]; then \
			$(MAKE) $(NOPRINTOPTION) -C $$target clean APPCPU_BUILD=1; \
		else \
			$(MAKE) $(NOPRINTOPTION) -C $$target clean; \
		fi \
	; done

realclean :
	@echo "Real cleaning in `pwd`"
	$(A)for i in $(ALLTARGETS) \
	; do \
		target=$$(echo $$i | sed 's/$(APPCPU_SUFFIX)//'); \
		if [ "$$i" != "$$target" ]; then \
			$(MAKE) $(NOPRINTOPTION) -C $$target realclean APPCPU_BUILD=1; \
		else \
			$(MAKE) $(NOPRINTOPTION) -C $$target realclean; \
		fi \
	; done
	$(A)-rm -rf bld

release :: $(PREREQS)
	$(MAKE)  -C $(REL_TARGET) $@ MAKECMDGOALS+=$(REL_TARGET)

checkvars ::
	$(A)$(MAKE)  -C rom $@

