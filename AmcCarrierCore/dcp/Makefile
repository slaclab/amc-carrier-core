# Define Firmware Version Number
export PRJ_VERSION = 0x02040700

# Define target output
target: dcp

export USE_XVC_DEBUG = -1

# Define target part
export PRJ_PART = XCKU040-FFVA1156-2-E

# Override the defaults
export TOP_DIR = $(abspath $(PROJ_DIR)/../../../..)
export PROJECT = AmcCarrierCore

# Use top level makefile
include ../../../ruckus/system_vivado.mk
