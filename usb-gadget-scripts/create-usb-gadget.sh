#!/bin/bash

# Script to create USB Gadgets for Zynthbox, on a Raspberry Pi
# - One USB Audio gadget, with 1 stereo input channel and 1 stereo output channel, at 48000Hz
# - One USB Audio gadget, 10 stereo output channels, at 48000Hz
# - One USB MIDI gadget
# - One USB Ethernet gadget

# call with --stop to stop the gadget and clean everything out

##################################
# USB Audio configuration:

CREATE_AUDIO_DEVICE_GLOBAL=1
CREATE_AUDIO_DEVICE_TRACKS=1

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
# One port for each track, and 1 for the global track
MIDI_INPUT_PORT_COUNT=11
# One port for each track, and 1 for the global track (this will output regardless of track mode, but will honour the settings for external track when a track is set to that mode)
MIDI_OUTPUT_PORT_COUNT=11

##################################
# USB Ethernet configuration

CREATE_ETHERNET_DEVICE=1

ETHERNET_HOST="00:dc:c8:f7:75:14"
ETHERNET_SELF="00:dd:dc:eb:6d:a1"

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

if (( $CREATE_AUDIO_DEVICE_GLOBAL == 1 )); then
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
fi

# The tracks output-only device
if (( $CREATE_AUDIO_DEVICE_TRACKS == 1 )); then
    mkdir -p functions/uac2.usb1
    echo $AUDIO_PLAYBACK_CHANNEL_MASK_TRACKS > functions/uac2.usb1/p_chmask
    echo $AUDIO_SAMPLE_RATES > functions/uac2.usb1/p_srate
    echo $AUDIO_SAMPLE_SIZE > functions/uac2.usb1/p_ssize
    echo $AUDIO_DEVICE_NAME_TRACKS > functions/uac2.usb1/function_name
    ln -s functions/uac2.usb1 configs/c.1/
fi

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

if (( $CREATE_ETHERNET_DEVICE == 1)); then
    # This section is heavily inspired by
    # - Ian Finch's script at https://gist.github.com/ianfinch/08288379b3575f360b64dee62a9f453f
    # - Ben's script at Ben's Place: https://blog.hardill.me.uk/2023/12/23/pi5-usb-c-gadget/
    if [[ ! -e /etc/network/interfaces.d/usb0 ]] ; then
        echo "auto usb0" > /etc/network/interfaces.d/usb0
        echo "allow-hotplug usb0" >> /etc/network/interfaces.d/usb0
        echo "iface usb0 inet static" >> /etc/network/interfaces.d/usb0
        echo "  address 10.55.0.1" >> /etc/network/interfaces.d/usb0
        echo "  netmask 255.255.255.248" >> /etc/network/interfaces.d/usb0
        echo "Created /etc/network/interfaces.d/usb0"
    fi
    # We create both an ECM and RNDIS interface, to ensure the device works with a variety of hosts
    # Create the ECM device
    mkdir -p functions/ecm.usb0
    HOST="00:dc:c8:f7:75:15" # "HostPC"
    SELF="00:dd:dc:eb:6d:a1" # "BadUSB"
    echo $HOST > functions/ecm.usb0/host_addr
    echo $SELF > functions/ecm.usb0/dev_addr
    ln -s functions/ecm.usb0 configs/c.1/
    # Create the RNDIS device
    ms_vendor_code="0xcd" # Microsoft
    ms_qw_sign="MSFT100" # also Microsoft (if you couldn't tell)
    ms_compat_id="RNDIS" # matches Windows RNDIS Drivers
    ms_subcompat_id="5162001" # matches Windows RNDIS 6.0 Driver
    mac="01:23:45:67:89:ab"
    dev_mac="02$(echo ${mac} | cut -b 3-)"
    host_mac="12$(echo ${mac} | cut -b 3-)"
    mkdir -p configs/c.2
    echo 0x80 > configs/c.2/bmAttributes
    echo 0x250 > configs/c.2/MaxPower
    mkdir -p configs/c.2/strings/0x409
    echo "RNDIS" > configs/c.2/strings/0x409/configuration
    mkdir -p functions/rndis.usb0
    echo "${dev_mac}" > functions/rndis.usb0/dev_addr
    echo "${host_mac}" > functions/rndis.usb0/host_addr
    echo "${ms_compat_id}" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
    echo "${ms_subcompat_id}" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
    ln -s functions/rndis.usb0 configs/c.2
    ln -s configs/c.2 os_desc
fi

# Ensure that all the devices have been created, and then write to enable the usb device controller
udevadm settle -t 5
ls /sys/class/udc > UDC

# TODO Not sure how to do this using not-networkmanager, assistance required...
# if (( $CREATE_ETHERNET_DEVICE == 1)); then
#     nmcli con add type bridge ifname br0
#     nmcli con add type bridge-slave ifname usb0 master br0
#     nmcli con add type bridge-slave ifname usb1 master br0
#     nmcli connection modify bridge-br0 ipv4.method manual ipv4.addresses 10.55.0.1/24
#
#     nmcli connection up bridge-br0
#     nmcli connection up bridge-slave-usb0
#     nmcli connection up bridge-slave-usb1
# fi

echo "Done"
