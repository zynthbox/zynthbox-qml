# USB Gadget for Audio and MIDI

The intent behind this set of scripts is to create a composite USB gadget setup
which provides a single-cable setup for the following:

* MIDI in and out for all tracks, plus global in and out
* Stereo audio input and output pair for the global (mirroring a balanced
  in/out pair)
* Stereo output pairs for each individual sketchpad track

We need to be able to turn this on and off at runtime, as there is some
performance impact for the audio clients. The midi client is functionally zero
impact, so that one just gets to exist). The global ones are quite low impact
(at 1% ish increase in dsp load on a raspbery pi 5), whereas the tracks client
is considerably higher impact (an around 7% to 8% dsp load increase on the
raspberry pi 5).

## Scripts

There are a total of six scripts here: One for creating the interfaces, a pair
of two each for starting and stopping them, and one systemd unit for running
the creation script on boot-up.

### create-usb-gadget.sh

Running this will create a usb gadget using libcomposite, which exposes three
separate functions on a single USB device as seen by a computer connected via
the client port on the device (the full-size B port on the hardware box).

Running the script with the argument "stop" will disable the gadget and remove
its configuration from the system.

### start-jack-usb-gadget-{global,tracks}.sh

Running these scripts will start the respective jack clients for each of the
input and outputs, for the part of the system as described by the script's
name. So, the global script for the stereo input and output pair, and tracks
for the output-only client with stereo pairs for each of the tracks.

### stop-jack-usb-gadget-{global,tracks}.sh

Running these scripts will stop the respective jack clients for each of the
input and outputs, for the system as described by the script's name.  So,
the global script for the stereo input and output pair, and tracks for the
output-only client with stereo pairs for each of the tracks.

### zynthbox-usb-gadget.service

Installing this unit will ensure the creation script is called as appropriate
for the given part of the system's life cycle (so, starting during boot-up,
after the usb gadget logic has been started, and stopped during shutdown,
before the usb gadget logic is shut down).
