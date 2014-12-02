TMPDIR ?= /tmp
tmpdir := $(shell mktemp -d $(TMPDIR)/initramfs-XXXXXX)

export LDFLAGS ?= -static
ifdef CROSS_COMPILE
export CC = $(CROSS_COMPILE)gcc
endif

.SILENT: initramfs.cpio

.PHONY: all initramfs.cpio clean

all: initramfs.cpio

packages	?= install-initramfs/ramfs.tgz

ifneq (0,${PROFILE})
packages	+= install-initramfs/profile.tgz
endif

ifneq (0,${RC_LOCAL})
packages	+= install-initramfs/rc.local.tgz
endif

ifneq (0,${NETWORKING})
packages	+= install-initramfs/networking.tgz
ifneq (0,${INET})
packages	+= install-initramfs/inetd.tgz
endif
endif

ifneq (0,${BUSYBOX})
packages	+= install-initramfs/busybox.tgz
clean		+= busybox_clean
mrproper	+= busybox_mrproper
include busybox.inc
endif

ifeq (1,${INPUT_EVENTD})
packages	+= install-initramfs/input-eventd.tgz
clean		+= input-eventd_clean
mrproper	+= input-eventd_mrproper
endif

install-initramfs/%.tgz:
	@echo -e "\e[1mBuilding package $*...\e[0m"
	( cd packages-initramfs/$* && tar czf ../../$@ --exclude=.gitignore * )

initramfs.cpio: $(packages)
	@echo -e "\e[1mGenerating $@...\e[0m"
	@for pkg in $(packages); do echo " - $${pkg##*/}"; done
	install -d $(tmpdir)/ramfs
	for dir in initramfs $(EXTRA); do find install-$$dir/ -name "*.tgz" -exec tar xzf {} -C $(tmpdir)/ramfs \;; done
	( cd $(tmpdir)/ramfs/ && find . | cpio -H newc -o >../$@ ) && cp $(tmpdir)/$@ .
	rm -Rf $(tmpdir)

clean:
	rm -Rf initramfs.cpio

mrproper: clean
	rm -Rf install-initramfs/*
