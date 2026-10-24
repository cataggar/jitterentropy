KERNELRELEASE ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KERNELRELEASE)/build

default: modules
install: modules_install

include Kbuild.config
include Kbuild.source

clean:
	$(MAKE) -C $(KDIR) M=$$PWD clean
	@- $(RM) $(jitter_rng-y)
	@- $(RM) $(join $(dir $(jitter_rng-y)), $(addprefix ., $(notdir $(jitter_rng-y:.o=.o.cmd))))
	@- $(RM) $(join $(dir $(jitter_rng-y)), $(addprefix ., $(notdir $(jitter_rng-y:.o=.o.d))))
	@- $(RM) -r .zig-cache

modules modules_install:
	# Compile the KO files
	$(MAKE) -C $(KDIR) M=$$PWD $@
