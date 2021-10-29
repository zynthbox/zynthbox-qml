BASEINSTALLDIR := $(DESTDIR)/home/pi/zynthian-ui

build-jackpeak:
	echo "  > Building jackpeak"
	cd zynlibs/jackpeak && bash build.sh

install-jackpeak: build-jackpeak
	echo "  > Installing jackpeak"
	mkdir -p $(BASEINSTALLDIR)/zynlibs/jackpeak/build
	find zynlibs/jackpeak/ -maxdepth 1 -type f -exec install -p {} $(BASEINSTALLDIR)/zynlibs/jackpeak \;
	cp zynlibs/jackpeak/build/libjackpeak.so $(BASEINSTALLDIR)/zynlibs/jackpeak/build


build-zynseq:
	echo "  > Building zynseq"
	cd zynlibs/zynseq && bash build.sh
	
install-zynseq: build-zynseq
	echo "  > Installing zynseq"
	mkdir -p $(BASEINSTALLDIR)/zynlibs/zynseq/build
	find zynlibs/zynseq/ -maxdepth 1 -type f -exec install -p {} $(BASEINSTALLDIR)/zynlibs/zynseq \;
	cp zynlibs/zynseq/build/libzynseq.so $(BASEINSTALLDIR)/zynlibs/zynseq/build


build-zynsmf:
	echo "  > Building zynsmf"
	cd zynlibs/zynsmf && bash build.sh
	
install-zynsmf: build-zynsmf
	echo "  > Installing zynsmf"
	mkdir -p $(BASEINSTALLDIR)/zynlibs/zynsmf/build
	find zynlibs/zynsmf/ -maxdepth 1 -type f -exec install -p {} $(BASEINSTALLDIR)/zynlibs/zynsmf \;
	cp zynlibs/zynsmf/build/libzynsmf.so $(BASEINSTALLDIR)/zynlibs/zynsmf/build


install-zynthian-qml:
	echo "  > Installing zynthian-qml"
	mkdir -p $(BASEINSTALLDIR)/
	find ./ -maxdepth 1 -not -name zynlibs -not -name . -not -name '.git*' -exec cp -pr $(shell realpath {}) $(BASEINSTALLDIR)/ \;


build: build-jackpeak build-zynseq build-zynsmf
	echo "- Building zynlibs"

install: install-jackpeak install-zynseq install-zynsmf install-zynthian-qml
	find $(BASEINSTALLDIR)/ -name "*.pyc" -type f -exec rm -rf $(shell realpath {}) \;
	find $(BASEINSTALLDIR)/ -name "*.qmlc" -type f -exec rm -rf $(shell realpath {}) \;
