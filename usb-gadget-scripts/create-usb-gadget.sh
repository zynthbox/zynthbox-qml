#!/bin/sh

# Script to create USB Gadgets for Zynthbox, on a Raspberry Pi
# - One USB Audio gadget, with 1 stereo input channel and 1 stereo output channel, at 48000Hz
# - One USB Audio gadget, 10 stereo output channels, at 48000Hz
# - One USB MIDI gadget

# call with --stop to stop the gadget and clean everything out

##################################
# USB Audio configuration:

# Channel mask is a binary list of which channels should be enabled (up to 27, as the final 5 spaces in the 32 bit flag space is used by other things internally to the driver)
# Examples:
# AUDIO_???_CHANNEL_MASK=255       # 8 channels (0b11111111)
# AUDIO_???_CHANNEL_MASK=65535     # 16 channels (0b1111111111111111)
# AUDIO_???_CHANNEL_MASK=16777215  # 24 channels (0b111111111111111111111111)
# AUDIO_???_CHANNEL_MASK=134217727 # 27 channels (0b111111111111111111111111111)
# For the first playback device, 2 channels (0b11) for the global output
AUDIO_PLAYBACK_CHANNEL_MASK=3
# For playback, 10 stereo channels, or 20 channels total (0b11111111111111111111) - one for each track
AUDIO_PLAYBACK_CHANNEL_MASK_TRACKS=1048575
# For capture, 1 stereo channel, or 2 channels (0b11) - maybe we want more, but this will do us until we decide otherwise
AUDIO_CAPTURE_CHANNEL_MASK=3

# A comma-separated list of supported sample rates in Hz (our system wants 48kHz, so just offer the one)
AUDIO_SAMPLE_RATES=48000
# The size of each sample in bytes (2 for 16-bit (S16_LE) and 4 for 32-bit little endian (S32_LE), and one would expect 3 for 24 bit)
AUDIO_SAMPLE_SIZE=4

AUDIO_DEVICE_NAME="Zynthbox Global"
AUDIO_DEVICE_NAME_TRACKS="Zynthbox Tracks"

##################################
# USB MIDI configuration

# Name of the MIDI device on the host machine
MIDI_ID="Zynthbox MIDI"
# One port for each track, and 1 for the current track
MIDI_INPUT_PORT_COUNT=11
# One port for each track, and 1 for the current track (this will output regardless of track mode, but will honour the settings for external track when a track is set to that mode)
MIDI_OUTPUT_PORT_COUNT=11


##################################
# The remaining parts of the script are the actual implementation of the work
# (if you only want to configure things, you can stop here)

# First step, get to the usb gadget settings dir
cd /sys/kernel/config/usb_gadget/

if [ "$1" = "stop" ]; then
    # the following logic is from https://github.com/larsks/systemd-usb-gadget/
    SYSDIR=/sys/kernel/config/usb_gadget/
    DEVDIR=$SYSDIR/zynthbox-gadget

    [ -d $DEVDIR ] || exit

    echo '' > $DEVDIR/UDC

    echo "Removing strings from configurations"
    for dir in $DEVDIR/configs/*/strings/*; do
            [ -d $dir ] && rmdir $dir
    done

    echo "Removing functions from configurations"
    for func in $DEVDIR/configs/*.*/*.*; do
            [ -e $func ] && rm $func
    done

    echo "Removing configurations"
    for conf in $DEVDIR/configs/*; do
            [ -d $conf ] && rmdir $conf
    done

    echo "Removing functions"
    for func in $DEVDIR/functions/*.*; do
            [ -d $func ] && rmdir $func
    done

    echo "Removing strings"
    for str in $DEVDIR/strings/*; do
            [ -d $str ] && rmdir $str
    done

    echo "Removing gadget"
    rmdir $DEVDIR

    exit 0
fi

echo "Creating Zynthbox USB Gadget"

# Just to be sure, load libcomposite: use this to enable multiple gadgets
modprobe libcomposite

# Create a composite gadget called zynthbox-gadget
mkdir -p zynthbox-gadget
cd zynthbox-gadget

# Set up our gadget's basic configuration
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
echo "high-speed" > max_speed
mkdir -p strings/0x409
echo "ZPZB0001" > strings/0x409/serialnumber
echo "Zynthbox Project" > strings/0x409/manufacturer
echo "Zynthbox" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Zynthbox Default" > configs/c.1/strings/0x409/configuration
echo 120 > configs/c.1/MaxPower

# Create our audio gadgets (UAC2)
# For a short description of the available attributes, see: https://www.kernel.org/doc/Documentation/ABI/testing/configfs-usb-gadget-uac2

# First the global input/output device
mkdir -p functions/uac2.usb0
echo $AUDIO_CAPTURE_CHANNEL_MASK > functions/uac2.usb0/c_chmask
echo $AUDIO_SAMPLE_RATES > functions/uac2.usb0/c_srate
echo $AUDIO_SAMPLE_SIZE > functions/uac2.usb0/c_ssize
echo $AUDIO_PLAYBACK_CHANNEL_MASK > functions/uac2.usb0/p_chmask
echo $AUDIO_SAMPLE_RATES > functions/uac2.usb0/p_srate
echo $AUDIO_SAMPLE_SIZE > functions/uac2.usb0/p_ssize
echo $AUDIO_DEVICE_NAME > functions/uac2.usb0/function_name
ln -s functions/uac2.usb0 configs/c.1/

# Then create the tracks output-only device
mkdir -p functions/uac2.usb1
echo $AUDIO_PLAYBACK_CHANNEL_MASK_TRACKS > functions/uac2.usb1/p_chmask
echo $AUDIO_SAMPLE_RATES > functions/uac2.usb1/p_srate
echo $AUDIO_SAMPLE_SIZE > functions/uac2.usb1/p_ssize
echo $AUDIO_DEVICE_NAME_TRACKS > functions/uac2.usb1/function_name
ln -s functions/uac2.usb1 configs/c.1/

# Create out MIDI gadget
# For a short description of the available attributes, see: https://www.kernel.org/doc/Documentation/ABI/testing/configfs-usb-gadget-midi
mkdir -p functions/midi.usb0
echo $MIDI_ID > functions/midi.usb0/id
echo $MIDI_INPUT_PORT_COUNT > functions/midi.usb0/in_ports
echo $MIDI_OUTPUT_PORT_COUNT > functions/midi.usb0/out_ports
echo 1024 > functions/midi.usb0/buflen
echo 128 > functions/midi.usb0/qlen
ln -s functions/midi.usb0 configs/c.1/
# mkdir -p functions/midi2.usb0
# echo $MIDI_ID > functions/midi2.usb0/iface_name
# mkdir -p functions/midi2.usb0/ep.0
# echo $MIDI_ID > functions/midi2.usb0/ep.0/ep_name
# echo "ZPZB0001" > functions/midi2.usb0/ep.0/product_id
# echo 0x0001 > functions/midi2.usb0/ep.0/family
# echo 0x0001 > functions/midi2.usb0/ep.0/model
# echo 0x123456 > functions/midi2.usb0/ep.0/manufacturer
# echo 0x00000001 > functions/midi2.usb0/ep.0/sw_revision
# echo 1 > functions/midi2.usb0/ep.0/protocol # 0 is "legacy", 1 is midi 1.0, 2 is midi 2.0
# mkdir -p functions/midi2.usb0/ep.0/block.0
# echo $MIDI_ID > functions/midi2.usb0/ep.0/block.0/name
# echo 0 > functions/midi2.usb0/ep.0/block.0/first_group
# echo 1 > functions/midi2.usb0/ep.0/block.0/num_groups
# ln -s functions/midi2.usb0 configs/c.1

# Ensure that all the devices have been created, and then write
udevadm settle -t 5
ls /sys/class/udc > UDC

echo "Done"
