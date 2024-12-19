#!/bin/sh

jack_load usb-gadget-in zalsa_in -i "-d hw:UAC2Gadget -w -n4 -p256 -c2 -v"
jack_load usb-gadget-global zalsa_out -i "-d hw:UAC2Gadget -w -n4 -p256 -c2 -v"
