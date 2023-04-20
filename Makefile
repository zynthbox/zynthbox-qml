BASEINSTALLDIR := $(DESTDIR)/home/pi/zynthbox-qml

.PHONY: install-zynthbox-qml
install-zynthbox-qml:
	echo "  > Installing zynthbox-qml"
	mkdir -p $(BASEINSTALLDIR)/
	find ./ \
		-maxdepth 1 \
		-not -name zynlibs \
		-not -name . \
		-not -name '*.deb' \
		-not -name 'debian' \
		-exec cp -pr $(shell realpath {}) $(BASEINSTALLDIR)/ \;


.PHONY: build
build:

.PHONY: install
install: install-zynthbox-qml
	find $(BASEINSTALLDIR)/ -name "*.pyc" -type f -exec rm -rf $(shell realpath {}) \;
	find $(BASEINSTALLDIR)/ -name "*.qmlc" -type f -exec rm -rf $(shell realpath {}) \;


.DEFAULT_GOAL := build
