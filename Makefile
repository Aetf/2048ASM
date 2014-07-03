mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

LINK = GoLink
ASM = GoAsm
RC = GoRc
DEBUGER = GoBug


NAME = 2048
PRECOMPILED_RES = 
LIBRARIES = Kernel32.dll User32.dll Gdi32.dll Ole32.dll AdvApi32.dll msvcrt.dll
LINK_FLAG = /debug coff
ASM_FLAG = 


TARGET = $(NAME).exe
RES = $(patsubst %.rc,%.res, $(wildcard *.rc))
OBJS = $(patsubst %.asm,%.obj,$(wildcard *.asm))
INCS = $(wildcard *.h)

INTERMIDATE_DIR = obj
OBJ_FILES = $(addprefix $(INTERMIDATE_DIR)/,$(OBJS))
RES_FILES = $(addprefix $(INTERMIDATE_DIR)/,$(RES))

all: $(TARGET)

$(TARGET): $(OBJ_FILES) $(RES_FILES)
	$(LINK) $(LINK_FLAG) /fo $@ $(PRECOMPILED_RES) $(LIBRARIES) $(subst /,\,$(OBJ_FILES)) $(subst /,\,$(RES_FILES))

./$(INTERMIDATE_DIR)/%.obj: %.asm $(INCS)
	$(ASM) $(ASM_FLAG) /sh /fo $@ $<

./$(INTERMIDATE_DIR)/%.res: %.rc
	$(RC) /r /fo $@ $<

clean:
	del /F /S /Q $(TARGET) $(RES) $(OBJS) $(INTERMIDATE_DIR)\*

run: $(TARGET)
	$(TARGET)

debug: $(TARGET)
	runasAdmin $(DEBUGER) $(TARGET)