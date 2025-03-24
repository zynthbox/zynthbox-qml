# Zynthbox

zynthbox-qml is part of [Zynthbox OS](https://zynthbox.io), an Open-source Music Workstation for fast and easy creation and capturing musical ideas, based on Raspberry Pi, Linux, and containing both powerful sample playback abilities, as well as a wide selection of Free and Open Source software synthesizers, such as synthv1, ZynAddSubFX, FluidSynth, SFizz, TAL-Noisemaker, and a wide variety of effects plugins.

The basic layout of the system is based around the concept of a musical Sketchpad, in which you can create sketches of your musical ideas. The idea is not that you should use this to create full and complete musical creations ready for publishing, but rather that you should use it to form ideas that you can then shape further in your DAW of choice.

## Guides and Documentation

These are a selection of guides and other documentation, describing specifics of Zynthbox, to help you more easily get to grips with it. Whether you are here to create music, or work on Zynthbox OS itself, this is your best pick for a starting point.

### Musical Creation

These guides focus on the creation of music using Zynthbox

+ [Introduction to the Sketchpad](docs/introduction.md) An quick introduction to the user interface and the basic concepts of Zynthbox OS, to help you jump in as quickly as possible and start making some music
+ [Your First Song](docs/your-first-song.md) A step by step guide from starting up Zynthbox, to having a full set of per-track recordings (or stems) of your creation, with a few optional detours along the way for the more adventurous
+ [Using the Sequencer](docs/using-the-sequencer.md) A comprehensive guide to using the sequencer built into Zynthbox
+ [Managing Sounds](docs/managing-sounds.md) A comprehensive guide to managing the things which make the sounds in your Sketchpad
+ [Sampling](docs/sampling.md) A comprehensive guide to creating and using the Zynthbox sampling system
+ [Controller Configuration](docs/controller-configuration.md) A comprehensive guide to how you can set up your midi controllers to best manage your workstation
+ [Introduction to Webconf](docs/webconf-introduction.md) A quick-start guide for how to use the browser based Webconf tool to manage your Zynthbox settings and resources (for example, how to transfer your own samples to the device)

### Modification and Development

These guides focus on how to extend Zynthbox using the tools built into the system, by creating shareable control surfaces, by using your own scripts, or even help with development of the system itself.

+ [Control Surfaces](docs/control-surfaces.md) How to use the build-in controls to construct your own controller surfaces for managing external instruments (either applications running on the Zynthbox, USB or MIDI 5-pin connected devices, a plugin running in a DAW on a host computer)
+ [Custom Pages](docs/custom-pages.md) How to create your own pages from scratch, for use as the edit page for any track
+ [Scripting API](docs/scripting-api.md) The API documentation for Zynthbox QML and libzynthbox, both accessible from within scripts on Zynthbox OS
+ [Contributing to Zynthbox OS](docs/contribute.md) How to set up your own development environment to work on Zynthbox OS itself, and contribute to the project directly

### Building and Installing

These guides focus on rolling your own Zynthbox installation, or building your own hardware kit for it to live on.

+ [Installation](docs/installation.md) This guide will show you the most minimal hardware setup required for getting up and running, plus a couple of optional extras, and how to do so (for those who are on a tight budget, or who want to dip a toe in before taking a big plunge)
+ [The Full Kit Build and Install](hardware repository location goes here) This is less of a guide and more simply the repository in which all the details you need to order your own PCBs and components, print an enclosure and so on, for those who want the full kit, but who would like to build it themselves

## Acknowledgments

This project was originally based around the [Zynthian](http://zynthian.org) Open Synth Platform, and while we have since departed greatly from what that platform intends to do, and indeed that code-base, we would have not got to where we are today without them as a starting off point. So, thank you to the Zynthian project!
