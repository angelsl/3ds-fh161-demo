#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
# SPECS is the directory containing the important build and link files
#---------------------------------------------------------------------------------
export TARGET		?=	$(shell basename $(CURDIR))
BUILD		:=	build
SOURCES		:=	source
INCLUDES	:=

#---------------------------------------------------------------------------------
# Setup some defines
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-marm -mthumb-interwork -march=armv5te -mtune=arm946e-s

CFLAGS	:=	-O2 -Wall -Wextra \
			-fomit-frame-pointer \
			-ffunction-sections -fdata-sections \
			-ffast-math -fdiagnostics-color=always \
			$(ARCH)

CFLAGS	+=	$(INCLUDE) -DARM9 -D_GNU_SOURCE

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions

ASFLAGS	:=	$(ARCH)
LDFLAGS	=	-T../stub.ld -nostartfiles -Wl,--gc-sections,-z,max-page-size=512

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(PORTLIBS)

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES_SRC	:= $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES := $(OFILES_SRC)
export HFILES	:= $(addsuffix .h,$(subst .,_,$(BINFILES)))

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: $(BUILD) clean all

#---------------------------------------------------------------------------------
all: $(BUILD) firm

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

firm: $(BUILD)
	@firmtool build boot9strap_ntr.firm -S spi-retail -g -D $(OUTPUT).elf arm11.elf -C NDMA XDMA
	@firmtool build $(TARGET).firm -S nand-retail -D $(OUTPUT).elf arm11.elf -C NDMA XDMA

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).bin $(TARGET).elf $(TARGET).firm


#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
#$(OUTPUT).bin	:	$(OUTPUT).elf
$(OUTPUT).elf	:	$(OFILES)

$(OFILES_SRC)	: $(HFILES)


#---------------------------------------------------------------------------------
#%.bin: %.elf
#	@$(OBJCOPY) -O binary $< $@
#	@echo built ... $(notdir $@)

#---------------------------------------------------------------------------------
%_bin.h %.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)


-include $(DEPENDS)


#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
