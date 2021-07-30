BINARY      := main

LDSCRIPT    := ch32f103c8t6.ld

LIBNAME     := opencm3_stm32f1
DEFS        += -DSTM32F1

FP_FLAGS    ?= -msoft-float
ARCH_FLAGS  := -mthumb -mcpu=cortex-m3 $(FP_FLAGS) -mfix-cortex-m3-ldrd

###############################################################################

SRC_DIR     := src
BIN_DIR     := build
OBJ_DIR     := $(BIN_DIR)/obj
INCLUDE_DIR := $(SRC_DIR) ./lib

SRC         := $(notdir $(wildcard $(SRC_DIR)/*.c))
SRC         += $(notdir $(wildcard $(SRC_DIR)/*.cpp))
SRC         += $(notdir $(wildcard $(SRC_DIR)/*.cxx))

OPENCM3_DIR := ./lib/libopencm3
INCLUDE_DIR += $(OPENCM3_DIR)/include

VPATH       := $(SRC_DIR)

###############################################################################

# Be silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
Q           := @
NULL        := 2>/dev/null
endif

###############################################################################
# Executables

PREFIX      ?= arm-none-eabi-

CC          := $(PREFIX)gcc
CXX         := $(PREFIX)g++
LD          := $(PREFIX)gcc
AR          := $(PREFIX)ar
AS          := $(PREFIX)as
OBJCOPY     := $(PREFIX)objcopy
OBJDUMP     := $(PREFIX)objdump
GDB         := $(PREFIX)gdb
SIZE        := $(PREFIX)size

###############################################################################
# Flags

OPT         := -Os
DEBUG       := -ggdb3
CSTD        ?= -std=c99

CFLAGS      += $(OPT) $(CSTD) $(DEBUG)
CFLAGS      += $(ARCH_FLAGS)
CFLAGS      += -Wextra -Wshadow -Wimplicit-function-declaration
CFLAGS      += -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes
CFLAGS      += -fno-common -ffunction-sections -fdata-sections

CXXFLAGS    += $(OPT) $(CXXSTD) $(DEBUG)
CXXFLAGS    += $(ARCH_FLAGS)
CXXFLAGS    += -Wextra -Wshadow -Wredundant-decls  -Weffc++
CXXFLAGS    += -fno-common -ffunction-sections -fdata-sections

CPPFLAGS    += -MD
CPPFLAGS    += -Wall -Wundef
CPPFLAGS    += $(DEFS) $(addprefix -I, $(INCLUDE_DIR))

LDFLAGS     += -L$(OPENCM3_DIR)/lib
LDFLAGS     += --static -nostartfiles
LDFLAGS     += -T$(LDSCRIPT)
LDFLAGS     += $(ARCH_FLAGS) $(DEBUG)
LDFLAGS     += -Wl,-Map=$(MAP) -Wl,--cref
LDFLAGS     += -Wl,--gc-sections
ifeq ($(V),99)
LDFLAGS     += -Wl,--print-gc-sections
endif

LDLIBS		+= -l$(LIBNAME) -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group

###############################################################################

ELF         := $(BIN_DIR)/$(BINARY).elf
HEX         := $(BIN_DIR)/$(BINARY).hex
BIN         := $(BIN_DIR)/$(BINARY).bin
MAP         := $(BIN_DIR)/$(BINARY).map
LIST        := $(BIN_DIR)/$(BINARY).list

OBJS        := $(SRC:.c=.o)
OBJS        := $(OBJS:.cpp=.o)
OBJS        := $(OBJS:.cxx=.o)
OBJ         := $(patsubst %,$(OBJ_DIR)/%,$(OBJS))

.PHONY: all clean list size

all: elf list size

elf: $(ELF)
bin: $(BIN)
hex: $(HEX)
list: $(LIST)

$(OPENCM3_DIR)/lib/lib$(LIBNAME).a:
ifeq (,$(wildcard $@))
	$(warning $(LIBNAME).a not found, attempting to rebuild in $(OPENCM3_DIR))
	$(MAKE) -C $(OPENCM3_DIR)
endif

$(ELF): $(OBJ) $(OPENCM3_DIR)/lib/lib$(LIBNAME).a | $(BIN_DIR)
	$(Q)$(LD) $(LDFLAGS) $(OBJ) $(LDLIBS) -o $@

$(OBJ): | $(OBJ_DIR)

$(OBJ_DIR)/%.o: %.c
	$(Q)$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.cpp
	$(Q)$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.cxx
	$(Q)$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(BIN_DIR) $(OBJ_DIR):
	$(Q) mkdir -p $@

$(HEX): $(ELF)
	$(Q)$(OBJCOPY) -O ihex "$(ELF)" "$(HEX)"

$(BIN): $(ELF)
	$(Q)$(OBJCOPY) -O binary "$(ELF)" "$(BIN)"

$(LIST): $(ELF)
	$(Q)$(OBJDUMP) -S "$(ELF)" > "$(LIST)"

flash: $(ELF)
	$(Q)openocd -f openocd.cfg -c """program $(ELF) verify reset exit"""

size: $(ELF)
	$(Q)$(SIZE) --format=berkeley $(ELF)

clean:
	@$(RM) -rv $(BIN_DIR)

-include $(OBJ:.o=.d)

