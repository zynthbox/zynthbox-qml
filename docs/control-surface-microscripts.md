# Control Surface Microscripts

This document describes in detail how to implement a Microscript. These are intended as a middle point between the UI layout tools available in Zynthbox OS, and a full custom implementation of a page as found in [Custom Pages](custom-pages.md). Their purpose is to allow you to both capture input from external devices and react to it, as well as handle translations between various types of input that would be awkward to implement in a generic fashion (for example for a hardware synth which has an uncommon layout for sysex commands for its control values).

Editing and creating microscripts is done using the [Webconf](webconf-introduction.md) tool, by going to the microscript editing section, accessed through the More &rarr; Microscripts menu. In there, you will be presented with a list of the microscripts found in each of the tracks on a given Sketchpad, by default the current one. You can easily copy microscripts between tracks via drag and drop, but the easiest option would be to make sure you create your microscript on the correct track to start with (which then saves you having to delete the one left behind).

## Some Useful Concepts

When creating the microscripts, you have full access to the entirety of the [Zynthbox scripting API](scripting-api.md), but you should be aware that some functions are called on an extremely regular basis during playback, and you should avoid putting overly heavy logic into those functions. These will be marked as "performance impact" in their descriptions below.

It is worth noting that when you are writing a script, it is not automatically attached to any object until you select it for a given controller on a [Control Surface](control-surfaces.md). What this means in practice is, each of these controllers have an instance of the Microscript. As a consequence, you will need to be aware of two things: Each instance is fully independent of all the other instances (so, for example, any properties you set on one instance will not change that property on another instance of the microscript), and you cannot access the other instances of your script directly. You can, however, access all active microscript instances on a track using the property `track.microscriptInstances` on the root object of your microscript.

That helpful property is not the only one, and you will also find a number of signals that you can defined signal handlers for. These are your primary entry points in the microscript, and in the structure section below, we will describe what these are. If you would like to learn much more about these concepts, the language we use to create these scripts is a JavaScript/ECMAScript variant called QML, and you can find documentation for that over on [the Qt website](https://doc.qt.io/qt-5/qtqml-index.html). We do hope, however, that the documentation here will be enough for you to not need to spend too much time there. However, if you are in need of some mathematics functionality, it is worth knowing that this is indeed a fully capable ECMAScript 6 interpreter, and that things such as the Math global is available to you. The examples below will show more of this in action.

## Microscript Structure



## Some Examples

This section shows you a few examples of microscripts, that you can copy and modify for your own purposes, or look at to learn from to make your own.

### Incoming Note Catcher

This will detect incoming note on messages, and collect them up in a list exposed as a property, until there is an equal number of off notes captured.

### Regular Note Outputter

This will use the sequencer's scheduling signals to send out a note at a regular interval.

### Checksum Generator

While you can simply tell the track that it is connected to a Roland device, and which one it is, and have SysexMessage add the checksum for you automatically, this shows how to implement such a checksum generator inside a Microscript, so that 
