#############################################################################
#	Makefile for the nanoManipulator client application.  Needs to be
# built using 'gmake'.  Should run on any architecture that is currently
# supported.  It should be possible to build simultaneously on multiple
# architectures.
#
# On the sgi, both g++ and CC verisons are built by default.
#
# Author: Russ Taylor, 10/2/1997
#	  
# modified:
# * Tom Hudson, 25 Jun 1998
#   Support for n32 ABI on sgi.  (gmake n32)
# * Hans Weber, ???
#   Support for both g++ and native compilers on sgi.
# * Tom Hudson, 13 Feb 1998
#   Build two different libraries:  client (libvrpn) and server
# (libvrpnserver).  Our solution is to compile twice, once with the
# flag -DVRPN_CLIENT_ONLY and once without.  Any server-specific code
# (vrpn_3Space, vrpn_Tracker_Fastrak, vrpn_Flock) should ONLY be compiled into
# the server library!
#############################################################################

##########################
# common definitions
#

MAKEFILE := Makefile
MAKE := gmake -f $(MAKEFILE)
HW_OS := $(shell hw_os)

# check if its for pxfl
ifdef PBASE_ROOT
  HW_OS := hp_flow
  ifeq ($(PXFL_COMPILER), aCC)
    HW_OS = hp_flow_aCC
  endif
endif

# Which C++ compiler to use.  Default is g++, but some don't use this.
#
# IF YOU CHANGE THESE, document either here or in the header comment
# why.  Multiple contradictory changes have been made recently.

# On the sgi, both g++ and CC versions are compiled by default.
# CC compiles default to old 32-bit format;  'gmake n32' builds -n32.


CC := g++
AR := ar

ifeq ($(FORCE_GPP),1)
  CC := g++
else

  ifeq ($(HW_OS),sgi_irix)
	SGI_CC_FLAGS := -32
	OBJECT_DIR_SUFFIX :=
	ifeq ($(SGI_ABI_N32),1)
		SGI_CC_FLAGS := -n32
		OBJECT_DIR_SUFFIX := .n32
	endif
	CC := CC $(SGI_CC_FLAGS)
  endif

  ifeq ($(HW_OS),hp700_hpux10)
	CC := CC +a1
  endif
  ifeq ($(HW_OS),sparc_sunos)
	CC := /usr/local/lib/CenterLine/bin/CC
  endif
  ifeq ($(HW_OS), hp_flow_aCC)
	CC := /opt/aCC/bin/aCC 
  endif
endif

ifeq ($(HW_OS),sparc_solaris)
  AR := /usr/ccs/bin/ar
endif

##########################
# directories
#

HMD_DIR 	 := /afs/cs.unc.edu/proj/hmd
HMD_INCLUDE_DIR	 := $(HMD_DIR)/include

BETA_DIR         := $(HMD_DIR)/beta
BETA_INCLUDE_DIR := $(BETA_DIR)/include
BETA_LIB_DIR     := $(BETA_DIR)/lib

# subdirectory for make
ifeq ($(FORCE_GPP),1)
OBJECT_DIR	 := $(HW_OS)/g++
SOBJECT_DIR      := $(HW_OS)/g++/server
else
UNQUAL_OBJECT_DIR := $(HW_OS)
UNQUAL_SOBJECT_DIR := $(HW_OS)/server
OBJECT_DIR	 := $(HW_OS)$(OBJECT_DIR_SUFFIX)
SOBJECT_DIR      := $(HW_OS)$(OBJECT_DIR_SUFFIX)/server
endif

##########################
# Include flags
#

SYS_INCLUDE := -I/usr/local/contrib/include -I/usr/local/contrib/mod/include

ifeq ($(HW_OS),pc_linux)
  SYS_INCLUDE := -I/usr/include -I/usr/local/contrib/include \
	  	 -I/usr/local/contrib/mod/include -I/usr/include/bsd \
		 -I/usr/include/g++
endif

ifeq ($(HW_OS),sgi_irix)
  SYS_INCLUDE := -I/usr/local/contrib/mod/include
endif

ifeq ($(HW_OS),hp700_hpux10) 
  SYS_INCLUDE := -I/usr/local/contrib/include -I/usr/local/contrib/mod/include \
                 -I/usr/include/bsd
endif

ifeq ($(HW_OS),hp_flow) 
  SYS_INCLUDE := -I/usr/local/contrib/include -I/usr/local/contrib/mod/include \
                 -I/usr/include/bsd -DFLOW
endif

ifeq ($(HW_OS),hp_flow_aCC) 
  SYS_INCLUDE := -I/usr/local/contrib/include -I/usr/local/contrib/mod/include \
                 -I/usr/include/bsd -DFLOW
endif

INCLUDE_FLAGS := -I. $(SYS_INCLUDE) -I$(BETA_INCLUDE_DIR) -I$(HMD_INCLUDE_DIR)

##########################
# Load flags
#

LOAD_FLAGS := -L./$(HW_OS) -L/usr/local/lib \
		-L/usr/local/contrib/unmod/lib -L/usr/local/contrib/mod/lib -g

ifeq ($(HW_OS),sgi_irix)
	LOAD_FLAGS := $(LOAD_FLAGS) -old_ld
endif

ifeq ($(HW_OS),pc_linux)
	LOAD_FLAGS := $(LOAD_FLAGS) -L/usr/X11R6/lib
endif

##########################
# Libraries
#

ifeq ($(HW_OS),pc_linux)
	ARCH_LIBS := -lbsd -ldl
else
#  ifeq ($(HW_OS),sparc_solaris)
#	ARCH_LIBS := -lsocket -lnsl
#  else
	ARCH_LIBS :=
#  endif
endif


LIBS := -lquat -lsdi $(TCL_LIBS) -lXext -lX11 $(ARCH_LIBS) -lm

#
# Defines for the compilation, CFLAGS
#

CFLAGS		 := $(INCLUDE_FLAGS) -g

#############################################################################
#
# implicit rule for all .c files
#
.SUFFIXES:	.c .C .o .a

.c.o:
	$(CC) -c $(CFLAGS) $<
.C.o:
	$(CC) -c $(CFLAGS) $<

# Build objects from .c files
$(OBJECT_DIR)/%.o: %.c $(LIB_INCLUDES) $(MAKEFILE)
	$(CC) $(CFLAGS) -o $@ -c $<

# Build objects from .C files
$(OBJECT_DIR)/%.o: %.C $(LIB_INCLUDES) $(MAKEFILE)
	$(CC) $(CFLAGS) -DVRPN_CLIENT_ONLY -o $@ -c $<

# Build objects from .C files
$(SOBJECT_DIR)/%.o: %.C $(LIB_INCLUDES) $(MAKEFILE)
	$(CC) $(CFLAGS) -o $@ -c $<

#
#
#############################################################################

# If we're building for sgi_irix, we need both g++ and non-g++ versions,
# unless we're building for one of the weird ABIs, which are only supported
# by the native compiler.

ifeq ($(HW_OS),sgi_irix)
  ifeq ($(SGI_ABI_N32),1)
all:	client server
  else
all:	client server client_g++ server_g++
  endif
else
all:	client server
endif

.PHONY:	n32
n32:
	$(MAKE) SGI_ABI_N32=1 all

.PHONY:	client_g++
client_g++:
	$(MAKE) FORCE_GPP=1 $(UNQUAL_OBJECT_DIR)/g++/libvrpn.a
	mv $(UNQUAL_OBJECT_DIR)/g++/libvrpn.a $(UNQUAL_OBJECT_DIR)/libvrpn_g++.a

.PHONY:	server_g++
server_g++:
	$(MAKE) FORCE_GPP=1 $(UNQUAL_OBJECT_DIR)/g++/libvrpnserver.a
	mv $(UNQUAL_OBJECT_DIR)/g++/libvrpnserver.a $(UNQUAL_OBJECT_DIR)/libvrpnserver_g++.a

.PHONY:	client
client:
	$(MAKE) $(OBJECT_DIR)/libvrpn.a

.PHONY:	server
server:
	$(MAKE) $(OBJECT_DIR)/libvrpnserver.a

$(OBJECT_DIR):
	-mkdir $(OBJECT_DIR)

$(SOBJECT_DIR):
	-mkdir $(SOBJECT_DIR)

#############################################################################
#
# library code
#
#############################################################################

# files to be compiled into the client library

LIB_FILES =  vrpn_Connection.C vrpn_Tracker.C vrpn_Button.C \
	     vrpn_Sound.C vrpn_ForceDevice.C vrpn_Clock.C vrpn_Shared.C \
	     vrpn_Ohmmeter.C vrpn_Analog.C vrpn_FileConnection.C \
             vrpn_FileController.C vrpn_Forwarder.C vrpn_Text.C \
             vrpn_ForwarderController.C vrpn_Serial.C

LIB_OBJECTS = $(patsubst %,$(OBJECT_DIR)/%,$(LIB_FILES:.C=.o))

LIB_INCLUDES = vrpn_Connection.h vrpn_Tracker.h vrpn_Button.h \
	       vrpn_Sound.h vrpn_ForceDevice.h vrpn_Clock.h vrpn_Shared.h \
	       vrpn_Ohmmeter.h vrpn_Analog.h vrpn_FileConnection.h \
               vrpn_FileController.h vrpn_Forwarder.h vrpn_Text.h \
               vrpn_ForwarderController.h vrpn_Serial.h

# Additional files to be compiled into the server library

# We aren't going to use architecture-dependent sets of files.
# If vrpn_sgibox isn't supposed to be compiled on any other architecture,
# then put all of it inside "#ifdef sgi"!

SLIB_FILES =  $(LIB_FILES) vrpn_3Space.C \
	     vrpn_Flock.C vrpn_Tracker_Fastrak.C vrpn_Dyna.C \
	     vrpn_Flock_Parallel.C  vrpn_Joystick.C \
	     vrpn_JoyFly.C vrpn_sgibox.C

SLIB_OBJECTS = $(patsubst %,$(SOBJECT_DIR)/%,$(SLIB_FILES:.C=.o))

SLIB_INCLUDES = $(LIB_INCLUDES) vrpn_3Space.h \
	       vrpn_Flock.h vrpn_Tracker_Fastrak.h vrpn_Dyna.h \
	       vrpn_Flock_Parallel.h vrpn_Joystick.h \
	       vrpn_JoyFly.h vrpn_sgibox.h


$(OBJECT_DIR)/libvrpn.a: $(MAKEFILE) $(OBJECT_DIR) $(LIB_OBJECTS) \
			$(LIB_INCLUDES)
	$(AR) ruv $(OBJECT_DIR)/libvrpn.a $(LIB_OBJECTS)
	-ranlib $(OBJECT_DIR)/libvrpn.a

$(OBJECT_DIR)/libvrpnserver.a: $(MAKEFILE) $(SOBJECT_DIR) $(SLIB_OBJECTS) \
			$(SLIB_INCLUDES)
	$(AR) ruv $(OBJECT_DIR)/libvrpnserver.a $(SLIB_OBJECTS)
	-ranlib $(OBJECT_DIR)/libvrpnserver.a

#############################################################################
#
# other stuff
#
#############################################################################

clean:
	\rm -f $(LIB_OBJECTS) $(OBJECT_DIR)/libvrpn.a $(OBJECT_DIR)/libvrpn_g++.a \
		$(SLIB_OBJECTS) $(OBJECT_DIR)/libvrpnserver.a $(OBJECT_DIR)/libvrpnserver_g++.a
ifneq ($(CC), g++)
	$(MAKE) FORCE_GPP=1 clean
endif

beta :
	$(MAKE) clean
	$(MAKE) all
	-mv $(OBJECT_DIR)/libvrpn.a $(OBJECT_DIR)/libvrpn_g++.a \
	    $(OBJECT_DIR)/libvrpnserver.a $(OBJECT_DIR)/libvrpnserver_g++.a \
            $(BETA_LIB_DIR)/$(OBJECT_DIR)
	-ranlib $(BETA_LIB_DIR)/$(OBJECT_DIR)/libvrpn.a
	-ranlib $(BETA_LIB_DIR)/$(OBJECT_DIR)/libvrpnserver.a
	-( cd $(BETA_INCLUDE_DIR); /bin/rm -f $(SLIB_INCLUDES) )
	cp $(SLIB_INCLUDES) $(BETA_INCLUDE_DIR) 

#############################################################################
#
# Dependencies that are non-obvious
#
