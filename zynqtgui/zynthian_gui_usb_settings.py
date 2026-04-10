#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian GUI USB Settings
#
# Copyright (C) 2026 Dan Leinir Turthra Jensen <admin@leinir.dk>
#
# ******************************************************************************
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# For a full copy of the GNU General Public License see the LICENSE.txt file.
#
# ******************************************************************************

import os
import logging
import subprocess
from pathlib import Path

from PySide2.QtCore import Signal, Property, Slot, Qt
from . import zynthian_qt_gui_base

class zynthian_gui_usb_settings(zynthian_qt_gui_base.zynqtgui):
    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")
    gadget_base_dir = Path("/sys/kernel/config/usb_gadget")
    gadget_name = "zynthbox-gadget"

    id_vendor = "0x1d6b"   # Linux Foundation
    id_product = "0x0104"  # Multifunction Composite Gadget
    bcd_device = "0x0100"  # v1.0.0
    bcd_usb = "0x0200"     # USB2
    max_speed = "high-speed"
    serial_number = "ZPZB0001"
    manufacturer = "Zynthbox Project"
    product = "Zynthbox"
    config_name = "Zynthbox Default"
    max_power = "120"

    # USB Audio configuration
    # Channel mask is a binary list of which channels should be enabled (up to 27, as the final 5
    # spaces in the 32 bit flag space are used by other things internally to the driver)
    # Examples:
    # mask = 255       # 8 channels  (0b11111111)
    # mask = 65535     # 16 channels (0b1111111111111111)
    # mask = 16777215  # 24 channels (0b111111111111111111111111)
    # mask = 134217727 # 27 channels (0b111111111111111111111111111)
    # For capture, 1 stereo channel, or 2 channels (0b11) - maybe we want more, but this will do us until we decide otherwise
    audio_capture_channel_mask = "3"
    # For the first playback device, 2 channels (0b11) for the global output
    audio_playback_channel_mask = "3"
    # For playback, 10 stereo channels, or 20 channels total (0b11111111111111111111) - one for each track
    audio_playback_channel_mask_tracks = "1048575"
    # A comma-separated list of supported sample rates in Hz (our system wants 48kHz, so just offer the one)
    audio_sample_rates = "48000"
    # The size of each sample in bytes (2 for 16-bit (S16_LE), 4 for 32-bit little endian (S32_LE), and one would expect 3 for 24 bit)
    audio_sample_size = "4"
    audio_device_name = "Zynthbox Global"
    audio_device_name_tracks = "Zynthbox Tracks"

    # USB MIDI configuration
    # Name of the MIDI device on the host machine
    midi_id = "Zynthbox MIDI"
    # One port for each track, and 1 for the global track
    midi_input_port_count = "11"
    # One port for each track, and 1 for the global track (this will output regardless of track mode,
    # but will honour the settings for external track when a track is set to that mode)
    midi_output_port_count = "11"
    midi_buflen = "1024"
    midi_qlen = "128"

    def __init__(self, parent=None):
        super(zynthian_gui_usb_settings, self).__init__(parent)
        self.__audioInterfaceStyle = int(self.zynqtgui.global_settings.value("USB/audioInterfaceStyle", 0))
        self.__midiPerTrack = True if self.zynqtgui.global_settings.value("USB/midiPerTrack", "true") == "true" else False
        self.__ethernet = True if self.zynqtgui.global_settings.value("USB/ethernet", "false") == "true" else False

        self.audioInterfaceStyleChanged.connect(self.restart_usb_gadget, Qt.QueuedConnection)
        self.midiPerTrackChanged.connect(self.restart_usb_gadget, Qt.QueuedConnection)
        self.ethernetChanged.connect(self.restart_usb_gadget, Qt.QueuedConnection)
        self.zynqtgui.isBootingCompleteChanged.connect(self.restart_usb_gadget, Qt.QueuedConnection)

    def fill_list(self):
        super().fill_list()

    def set_select_path(self):
        self.select_path = "UsbSettings"
        self.select_path_element = "UsbSettings"
        super().set_select_path()

    # Creates USB Gadgets for Zynthbox, on a Raspberry Pi:
    # - One USB Audio gadget, with 1 stereo input channel and 1 stereo output channel, at 48000Hz
    # - One USB Audio gadget, 10 stereo output channels, at 48000Hz
    # - One USB MIDI gadget
    @Slot()
    def restart_usb_gadget(self):
        gadget_dir = self.gadget_base_dir / self.gadget_name
        config_dir = gadget_dir / "configs" / "c.1"

        try:
            # Just to be sure, load libcomposite: use this to enable multiple gadgets
            subprocess.run(["modprobe", "libcomposite"], check=True)

            if gadget_dir.exists():
                self.stop_usb_gadget()

            # Create a composite gadget called zynthbox-gadget
            gadget_dir.mkdir(parents=True, exist_ok=True)

            # Set up our gadget's basic configuration
            (gadget_dir / "idVendor").write_text(self.id_vendor, encoding="utf-8")
            (gadget_dir / "idProduct").write_text(self.id_product, encoding="utf-8")
            (gadget_dir / "bcdDevice").write_text(self.bcd_device, encoding="utf-8")
            (gadget_dir / "bcdUSB").write_text(self.bcd_usb, encoding="utf-8")
            (gadget_dir / "max_speed").write_text(self.max_speed, encoding="utf-8")

            strings_dir = gadget_dir / "strings" / "0x409"
            strings_dir.mkdir(parents=True, exist_ok=True)
            (strings_dir / "serialnumber").write_text(self.serial_number, encoding="utf-8")
            (strings_dir / "manufacturer").write_text(self.manufacturer, encoding="utf-8")
            (strings_dir / "product").write_text(self.product, encoding="utf-8")

            config_strings_dir = config_dir / "strings" / "0x409"
            config_strings_dir.mkdir(parents=True, exist_ok=True)
            (config_strings_dir / "configuration").write_text(self.config_name, encoding="utf-8")
            (config_dir / "MaxPower").write_text(self.max_power, encoding="utf-8")

            # Create our audio gadgets (UAC2)
            # For a short description of the available attributes, see:
            # https://www.kernel.org/doc/Documentation/ABI/testing/configfs-usb-gadget-uac2
            if self.__audioInterfaceStyle >= 1:
                logging.info("Creating Global Output USB Audio Gadget")
                # The global input/output device
                global_audio = gadget_dir / "functions" / "uac2.usb0"
                global_audio.mkdir(parents=True, exist_ok=True)
                (global_audio / "c_chmask").write_text(self.audio_capture_channel_mask, encoding="utf-8")
                (global_audio / "c_srate").write_text(self.audio_sample_rates, encoding="utf-8")
                (global_audio / "c_ssize").write_text(self.audio_sample_size, encoding="utf-8")
                (global_audio / "p_chmask").write_text(self.audio_playback_channel_mask, encoding="utf-8")
                (global_audio / "p_srate").write_text(self.audio_sample_rates, encoding="utf-8")
                (global_audio / "p_ssize").write_text(self.audio_sample_size, encoding="utf-8")
                (global_audio / "function_name").write_text(self.audio_device_name, encoding="utf-8")
                global_audio_link = config_dir / "uac2.usb0"
                if global_audio_link.exists() or global_audio_link.is_symlink():
                    global_audio_link.unlink()
                global_audio_link.symlink_to(global_audio)

            if self.__audioInterfaceStyle >= 2:
                logging.info("Creating Tracks Output USB Audio Gadget")
                # The tracks output-only device
                tracks_audio = gadget_dir / "functions" / "uac2.usb1"
                tracks_audio.mkdir(parents=True, exist_ok=True)
                (tracks_audio / "p_chmask").write_text(self.audio_playback_channel_mask_tracks, encoding="utf-8")
                (tracks_audio / "p_srate").write_text(self.audio_sample_rates, encoding="utf-8")
                (tracks_audio / "p_ssize").write_text(self.audio_sample_size, encoding="utf-8")
                (tracks_audio / "function_name").write_text(self.audio_device_name_tracks, encoding="utf-8")
                tracks_audio_link = config_dir / "uac2.usb1"
                if tracks_audio_link.exists() or tracks_audio_link.is_symlink():
                    tracks_audio_link.unlink()
                tracks_audio_link.symlink_to(tracks_audio)

            # Create our MIDI gadget
            # For a short description of the available attributes, see:
            # https://www.kernel.org/doc/Documentation/ABI/testing/configfs-usb-gadget-midi
            logging.info("Creating USB MIDI Gadget")
            midi = gadget_dir / "functions" / "midi.usb0"
            midi.mkdir(parents=True, exist_ok=True)
            (midi / "id").write_text(self.midi_id, encoding="utf-8")
            (midi / "in_ports").write_text(str(self.midi_input_port_count if self.__midiPerTrack else 1), encoding="utf-8")
            (midi / "out_ports").write_text(str(self.midi_output_port_count if self.__midiPerTrack else 1), encoding="utf-8")
            (midi / "buflen").write_text(self.midi_buflen, encoding="utf-8")
            (midi / "qlen").write_text(self.midi_qlen, encoding="utf-8")
            midi_link = config_dir / "midi.usb0"
            if midi_link.exists() or midi_link.is_symlink():
                midi_link.unlink()
            midi_link.symlink_to(midi)

            # Ensure that all the devices have been created, and then write to enable the usb device controller
            subprocess.run(["udevadm", "settle", "-t", "5"], check=True)

            udc_entries = sorted(Path("/sys/class/udc").iterdir(), key=lambda entry: entry.name)
            if len(udc_entries) == 0:
                logging.error("No UDC controller found in /sys/class/udc")
            else:
                (gadget_dir / "UDC").write_text(udc_entries[0].name, encoding="utf-8")
        except Exception as err:
            logging.exception("Failed to start USB gadget: %s", err)

    def stop_usb_gadget(self):
        # Run the stop shell script to cleanly stop the gadget, and remove any existing gadget directory
        try:
            logging.info("Removing USB Audio and MIDI Gadget")
            subprocess.run(["/bin/bash", str(Path(self.sys_dir) / "sbin/stop-usb-gadget.sh")], check=True)
        except Exception as err:
            logging.exception("Failed to stop USB gadget: %s", err)

    ### BEGIN Property audioInterfaceStyle
    # 0 is no audio interface
    # 1 is global stereo pair only
    # 2 is global and per-track stereo pair
    def get_audioInterfaceStyle(self):
        return self.__audioInterfaceStyle

    def set_audioInterfaceStyle(self, value):
        if value != self.__audioInterfaceStyle:
            self.__audioInterfaceStyle = value
            self.zynqtgui.global_settings.setValue("USB/audioInterfaceStyle", self.__audioInterfaceStyle)
            self.audioInterfaceStyleChanged.emit()

    audioInterfaceStyleChanged = Signal()

    audioInterfaceStyle = Property(int, get_audioInterfaceStyle, set_audioInterfaceStyle, notify=audioInterfaceStyleChanged)
    ### END Property audioInterfaceStyle

    ### BEGIN Property midiPerTrack
    def get_midiPerTrack(self):
        return self.__midiPerTrack

    def set_midiPerTrack(self, value):
        if value != self.__midiPerTrack:
            self.__midiPerTrack = value
            self.zynqtgui.global_settings.setValue("USB/midiPerTrack", self.__midiPerTrack)
            self.midiPerTrackChanged.emit()

    midiPerTrackChanged = Signal()

    midiPerTrack = Property(bool, get_midiPerTrack, set_midiPerTrack, notify=midiPerTrackChanged)
    ### END Property midiPerTrack

    ### BEGIN Property ethernet
    def get_ethernet(self):
        return self.__ethernet

    def set_ethernet(self, value):
        if value != self.__ethernet:
            self.__ethernet = value
            self.zynqtgui.global_settings.setValue("USB/ethernet", self.__ethernet)
            self.ethernetChanged.emit()

    ethernetChanged = Signal()

    ethernet = Property(bool, get_ethernet, set_ethernet, notify=ethernetChanged)
    ### END Property ethernet

# ------------------------------------------------------------------------------
