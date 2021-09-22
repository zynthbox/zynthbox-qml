/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Base Play Grid Component 

Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
Copyright (C) 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

******************************************************************************

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

For a full copy of the GNU General Public License see the LICENSE.txt file.

******************************************************************************
*/

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

/**
 * \brief This is the base component for all PlayGrids
 *
 * PlayGrids are, as the name suggests, freeform play areas that can be used most commonly to control
 * notes played through the various instruments Zynthian supports via midi.
 *
 * \section basics The Basic Structure
 *
 * A PlayGrid has a number of basic properties that you will need to set for it to be useful:
 *
 * * name: The name of your playgrid
 * * icon: A small graphic used to represent your playgrid
 * * grid: The component which is used in the PlayGrid section to paint the main area
 * * miniGrid: The component which is used in the popup mini grid
 * * settings: The component used to display settings to the user in the main PlayGrid section's settings dialog
 * * sidebar: An optional component you can use to override the sidebar in the main PlayGrid section
 * * popup: An optional component used to paint in the area shown beside the menu popup in the main PlayGrid section
 *
 * The `initialize` signal is your entrypoint for setting things up. Use this signal to perform any
 * initialisation work that is needed for your playgrid. A few important points that you should make
 * a note of:
 *
 * * Don't do heavy operations in the initialisation handler. This is run when entering the PlayGrid
 *   section, and will want to be as fast as possible.
 * * Throttle any regeneration of your model (this can be heavy and will impact the performance of
 *   your playgrid, which will make it look silly). You can do this by having any regeneration done
 *   through a timer instead of directly calling it on properties changing.
 *
 * \section notes Notes
 *
 * A basic function of most any PlayGrid is going to be managing notes (that is, representations of
 * some musical note), and both starting and stopping those. The following functions are those which
 * are important for that purpose:
 *
 * * getModel: Fetches a model in which you can store note objects
 * * getNote: Fetches an object which represents a specific midi note
 * * getCompoundNote: Fetches an object which represents multiple midi notes
 * * setNoteOn/setNoteOff: Turns the note passed to the function on or off
 * * setNotesOn/setNotesOff: As above, except they work with multiple notes for convenience
 *
 * @note When fetching your model, you can use the `rows` property to check whether it has already
 * been filled (which can save considerable resources by avoiding filling an already filled model)
 *
 * \section settings Settings
 *
 * Your PlayGrid is able to store settings by using a set of functions and properties on the base
 * component. You can set a set of defaults, and then set, get, and clear properties. Clearing a
 * property will revert it back to the default (if you have not defined a default, the value will be
 * `undefined`).
 *
 * * defaults is be a dictionary which contains sets of property names and their default values.
 *   As an example, this might be \code defaults: { "some property": "a value", "list property": [] } \endcode
 * * persist is a list of property names for those properties whose values should be kept between
 *   sessions (if this is not defined, no settings will be stored)
 * * setProperty() will set the value of the property you pass the name of
 * * getProperty() will get the value of the property you pass the name of (or the default value if
 *   none has been set explicitly by calling setProperty above)
 * * clearProperty() will clear the explicitly set value of the named property (causing a subsequent call
 *   to getProperty to return the default value). If you need it set to something empty, but have a
 *   default defined, you will need to set that explicitly.
 *
 * \subsection storage Data Storage
 *
 * Your PlayGrid has a unique area in which it is allowed to store data. You can use the saveData
 * and loadData functions to do this. The data must be in the form of a string. We recommend json,
 * since we generally use this internally, and there are convenient ways of dealing with the format
 * built in to QML through the ECMAScript JSON functions, but any string data can be stored.
 *
 * This is stored alongside the playgrid's settings, which also mean you must avoid using the key
 * "settings", as that is the key in which the properties are persisted to. The call will fail
 * if you attempt to use this key for saving, and return false, but you can use loadData to see
 * what it will return (this only happens to avoid unintentionally ruining your own playgrid).
 *
 * \section metronome The Metronome/ Beat Timer
 *
 * The PlayGrid subsystem provides you with a way to perform simple beat based operations, based on
 * a simple beat-sliced timer, which will give you a tick every so many subdivisions of a beat:
 *
 * * metronome4thBeat, metronome8thBeat, and metronome16thBeat are properties, and will change each
 *   time that subdivision of a beat has passed by (and will contain the number of the subdivision,
 *   so for example metronome8thBeat will contain the numbers from 1 through 8).
 * * startMetronome() and stopMetronome() will start and stop the metronome respectively
 *
 * \section pitchmod Pitch/Mod Support
 *
 * To make it a little more fun to play with, there is support for pitch and modulation shifting in
 * the playgrid. Just set the two appropriate properties, pitch and modulation, to appropriate values
 * and your notes will pitch shift and modulate as you desire.
 *
 * \section example An Example
 *
 * The following is an example of a very simple playgrid, which uses the same component for both main
 * and minigrid. It shows the basic functionality of the playgrid (not including metronome, pitch/mod
 * and the like), just the very most basic things that you're going to need for basically any playgrid.
 *
 * \include[lineno]{BasePlayGrid-example.qml}
 */
Item {
    id: component

    /**
     * \brief The human-facing name of your playgrid (shown anywhere the grid is referred to in the UI)
     *
     * You should not make this overly long or awkward, as it is used as the visual identifier by your user.
     * Clever is fine, but always remember: unique is not a selling point in its own right.
     */
    property string name
    /**
     * \brief An icon used to represent the playgrid in the UI (in places where an icon makes sense)
     *
     * Either the name of an icon, as available on Zynthian, or the local filesystem location of one.
     * If you don't set one, this will default to using a generic grid styled icon
     */
    property string icon: "view-grid-symbolic"
    /**
     * \brief A component which is used for the large grid (in the PlayGrid section of Zynthian)
     *
     * This component should expect to take up most of the display
     */
    property Component grid
    /**
     * \brief A component used for the popup mini grid available throughout Zynthian
     *
     * This component should expect most of the display width (same width as the main grid), but
     * should expect at most a third of the height of the display.
     *
     * By default, miniGrid is bound to the grid property, ensuring things work even if one is
     * not explicitly created (at which point, you should ensure grid will scale down correctly)
     */
    property Component miniGrid: component.grid
    /**
     * \brief A component used for displaying options in the PlayGrid Settings dialog
     *
     * Optimally, you will use a Kirigami.FormLayout for this component, so that it will scale
     * appropriately, given different screen sizes
     */
    property Component settings
    /**
     * \brief If defined, a component which replaces the sidebar in the PlayGrid section of Zynthian
     *
     * Default is none, as the system has a default sidebar for those playgrids where basic
     * octave/mod/pitch controls make sense. This sidebar is not shown for minigrids, and your minigrid
     * should function without.
     */
    property Component sidebar
    /**
     * \brief If defined, a component which is shown in the area beside the menu popup in the PlayGrid section of Zynthian
     *
     * Default is none, which results in the area just being empty (transparent, so it will not look
     * broken). If there is a need, this is a panel the size of about a third of the screen width and
     * about the height of the playgrid which can contain anything, and which is shown beside the
     * playgrid popup menu on the main playgrid (not for miniGrids).
     */
    property Component popup
    /**
     * \brief Whether or not this playgrid makes use of the octave setting in the sidebar
     *
     * If this is set to false, the octave buttons in the sidebar will be disabled
     */
    property bool useOctaves: true
    /**
     * \brief The octave PlayGrid would prefer you to use
     *
     * This property is set by the PlayGrid subsystem itself, and is essentially just a handy shortcut
     * to being told where to start generating notes from. In other words, you are entirely free to
     * ignore this, but if you do, you should set `useOctaves` to false.
     */
    property int octave: 3

    /**
     * \brief The signal which you should use to perform initialisations of your playgrid
     *
     * This signal should be used for initialising your playgrid, in place of Component.onCompleted
     */
    signal initialize();

    /**
     * \brief A way to set the pitch shift value (between -8192 and 8191, 0 being no shift)
     */
    property int pitch
    onPitchChanged: {
        if (zynthian.playgrid.pitch !== component.pitch) {
            zynthian.playgrid.pitch = component.pitch;
        }
    }
    /**
     * \brief A way to set the modulation value (between -127 and 127, with 0 being no modulation)
     */
    property int modulation
    onModulationChanged: {
        if (zynthian.playgrid.modulation !== component.modulation) {
            zynthian.playgrid.modulation = component.modulation;
        }
    }
    Connections {
        target: zynthian.playgrid
        onPitchChanged: {
            if (zynthian.playgrid.pitch !== component.pitch) {
                component.pitch = zynthian.playgrid.pitch
            }
        }
        onModulationChanged: {
            if (zynthian.playgrid.modulation !== component.modulation) {
                component.modulation = zynthian.playgrid.modulation
            }
        }
    }

    /**
     * \brief Start the system which provides beat updates
     *
     * Use the properties matching the beat division you need (metronome4thBeat and so on),
     * in which you will be told at which subdivision of the beat you are at. The counter
     * in the properties is 1-indexed, meaning you get numbers from 1 through the number of
     * the division.
     *
     * @see stopMetronome()
     */
    function startMetronome() {
        zynthian.playgrid.startMetronomeRequest();
    }
    /**
     * \brief Stop the beat updates being sent into the playgrid
     * @see startMetronome()
     */
    function stopMetronome() {
        zynthian.playgrid.stopMetronomeRequest();
    }

    /**
     * \brief A number which changes from 1 through 4 every 4th beat when the metronome is running
     * @see startMetronome()
     * @see stopMetronome()
     */
    property int metronome4thBeat;
    Binding {
        target: component
        property: "metronome4thBeat"
        value: zynthian.playgrid.metronome4thBeat
    }

    /**
     * \brief A number which changes from 1 through 8 every 8th beat when the metronome is running
     * @see startMetronome()
     * @see stopMetronome()
     */
    property int metronome8thBeat;
    Binding {
        target: component
        property: "metronome8thBeat"
        value: zynthian.playgrid.metronome8thBeat
    }

    /**
     * \brief A number which changes from 1 through 16 every 16th beat when the metronome is running
     * @see startMetronome()
     * @see stopMetronome()
     */
    property int metronome16thBeat;
    Binding {
        target: component
        property: "metronome16thBeat"
        value: zynthian.playgrid.metronome16thBeat
    }

    /**
     * \brief Turns the note passed to it on, if it is not already playing
     *
     * This will turn on the note, but it will not turn the note off and back on again if it is already
     * turned on. If you wish to release and fire the note again, you can either check the note's
     * isPlaying property first and then turn it off first, or you can simply call setNoteOff, and then
     * call setNoteOn immediately.
     *
     * @param note The note which should be turned on
     * @param velocity The velocity at which the note should be played (defaults to 64)
     */
    function setNoteOn(note, velocity)
    {
        if (velocity == undefined) {
            zynthian.playgrid.setNoteOn(note, 64);
        } else {
            zynthian.playgrid.setNoteOn(note, velocity);
        }
    }
    /**
     * \brief Turns the note passed to it off
     *
     * @param note The note which should be turned off
     */
    function setNoteOff(note)
    {
        zynthian.playgrid.setNoteOff(note);
    }
    /**
     * \brief Turn a list of notes on, with the specified velocities
     *
     * @param notes A list of notes
     * @param velocities A list of velocities (must be equal length to notes)
     */
    function setNotesOn(notes, velocities)
    {
        zynthian.setNotesOn(notes, velocities);
    }
    /**
     * \brief Turn a list of notes off
     *
     * @param notes A list of notes
     */
    function setNotesOff(notes)
    {
        zynthian.playgrid.setNotesOff(notes);
    }

    /**
     * \brief Get a note object representing the midi note passed to it
     *
     * @param midiNote The midi note you want an object representation of
     * @return The note representing the specified midi note
     */
    function getNote(midiNote)
    {
        var scale_index = 0; // This seems to be entirely unneeded...
        var note_int_to_str_map = ["C", "C#","D","D#","E","F","F#","G","G#","A","A#","B"];
        var note = zynthian.playgrid.getNote(
            note_int_to_str_map[midiNote % 12],
            scale_index,
            Math.floor(midiNote / 12),
            midiNote
        );
        return note;
    }
    /**
     * \brief Get a single note representing a single note
     *
     * @param notes A list of note objects
     * @return The single note representing all the notes passed to the function
     */
    function getCompoundNote(notes)
    {
        return zynthian.playgrid.getCompoundNote(notes);
    }
    /**
     * \brief Returns a model suitable for storing notes in
     *
     * Use this function to fetch a named model, which will persist for the duration of the application
     * session. What this means is that you can use this function to get a specific model that you have
     * previously created, and avoid having to refill it every time you need to show your playgrid. You
     * can thus fetch this model, and before attempting to fill it up, you can check whether there are
     * any notes in the model already, by using the `rows` property on it to check how many rows of
     * notes are currently in the model.
     *
     * @param modelName The name of the model
     * @return A model with the given name
     */
    function getModel(modelName)
    {
        return zynthian.playgrid.getNotesModel(component.name + modelName);
    }

    /**
     * \brief The default values of properties you wish to interact with
     *
     * A key/value pairing of property names and their default values
     */
    property variant defaults: {}
    /**
     * \brief The names of the properties whose values should be saved between sessions
     *
     * Setting this property will ensure that any setting which matches a name in the list will be saved
     * to disk when changed in the UI, and also loaded back from disk the next time the PlayGrid is
     * initialised.
     *
     * If you leave this list empty, no properties will be saved between sessions.
     */
    property variant persist: []
    /**
     * \brief A signal which is fired whenever a property changes (with property name, and new value)
     *
     * @param property The name of the property which has changed
     * @param value The new value of the property
     */
    signal propertyChanged(string property, var value);
    /**
     * \brief Fetch the value of the named property
     *
     * This function will return either the currently set value of a property, or the default value if
     * the property has not had any other value set on it.
     *
     * @param property The name of the value to fetch the value of
     * @return The value of the named property
     */
    function getProperty(property)
    {
        return _private.getProperty(property)
    }
    /**
     * \brief Set the value of the named property
     *
     * It is safe to set the property to the same value it previously held, as the changed signal will
     * not be fired for the property unless the value has actually changed. This includes setting it to
     * the default value, even if there was previously no explicitly set value for that property.
     *
     * @param property The name of the property you wish to set
     * @param value The new value for the property
     */
    function setProperty(property, value)
    {
        _private.setProperty(property, value);
    }
    /**
     * \brief Clear the explicitly set value of the named property
     *
     * This will clear the property of any explicitly set value, and revert it to hold the default value
     * if one exists. If no default exists, the new value will be `undefined`. It is safe to clear an
     * already cleared property, as the changed signal will only be fired if the default value is
     * different to the value the property previously held.
     *
     * @param property The name of the property you wish to clear
     */
    function clearProperty(property)
    {
        _private.clearProperty();
    }

    /**
     * \brief Load a string value saved to disk under a specified name
     * @param key The name of the data you wish to retrieve
     * @return A string containing the data contained in the specified key (an empty string if none was found)
     */
    function loadData(key)
    {
        return _private.loadData(key);
    }
    /**
     * \brief Save a string value to disk under a specified name
     *
     * @note The key will be turned into a filesystem-safe string before attempting to save the data
     *       to disk. This also means that if you are overly clever with naming, you may end up with
     *       naming clashes. In other words, be sensible in naming your keys, and your behaviour will
     *       be more predictable.
     * @param key The name of the data you wish to store
     * @param data The contents you wish to store, in string form
     * @return True if successful, false if unsuccessful
     */
    function saveData(key, data)
    {
        return _private.saveData(key, data);
    }
    Component.onCompleted: {
        _private.loadSettings();
        initialisationTimer.restart();
    }
    Component.onDestruction: {
        _private.saveSettings();
    }
    Timer {
        id: initialisationTimer
        interval: 1
        repeat: false
        onTriggered: {
            component.initialize()
        }
    }

    QtObject {
        id: _private
        property QtObject settingsContainer: null;
        function ensureContainer()
        {
            if (settingsContainer == null) {
                settingsContainer = zynthian.playgrid.getSettingsStore(component.name);
            }
        }
        function listsEqual(list1, list2) {
            var equal = true;
            if (list1.length === list2.length) {
                for (var i = 0; i < list1.length; ++i) {
                    if (list1[i] !== list2[i]) {
                        equal = false;
                        break;
                    }
                }
            } else {
                equal = false;
            }
            return equal;
        }

        function getProperty(property)
        {
            ensureContainer();
            var value = settingsContainer.getProperty(property);
            //console.log("Fetching property " + property)
            if (value == undefined) {
                value = component.defaults[property];
                //console.log("No value set, returning default " + value + " out of " + component.defaults);
            }
            return value
        }

        function setProperty(property, value)
        {
            ensureContainer();
            if (settingsContainer.getProperty(property) != value) {
                var oldValue = getProperty(property)
                settingsContainer.setProperty(property, value);
                if (Array.isArray(value) && Array.isArray(oldValue)) {
                    if (!listsEqual(value, oldValue)) {
                        component.propertyChanged(property, value);
                        settingsSaver.restart();
                    }
                } else if (oldValue != value) {
                    component.propertyChanged(property, value);
                    settingsSaver.restart();
                }
            }
        }

        function clearProperty(property)
        {
            ensureContainer();
            oldValue = getProperty(property);
            settingsContainer.clearProperty(property);
            newValue = getProperty(property);
            if (oldValue != newValue) {
                component.propertyChanged(property, newValue);
                settingsSaver.restart();
            }
        }

        function loadData(key)
        {
            ensureContainer();
            return settingsContainer.loadData(key);
        }

        function saveData(key, data)
        {
            var success = false;
            if (key == "settings") {
                ensureContainer();
                success = settingsContainer.saveData(key, data);
            }
            return success;
        }

        function loadSettings()
        {
            ensureContainer()
            var jsonString = settingsContainer.loadData("settings")
//             console.log("Loading settings for " + component.name + " which has the following data available: " + jsonString);
            if (jsonString.length > 2) { // an empty json object is just {}, so we can ignore that situation
                var loadedData = JSON.parse(jsonString);
                //console.log("That string was longer than 0, and parsed it becomes: " + loadedData);
                for (var i = 0; i < component.persist.length; ++i) {
                    var propName = component.persist[i];
                    //console.log("Resetting, and checking if it contains a value for " + propName);
                    var oldValue = getProperty(propName);
                    settingsContainer.clearProperty(propName);
                    if (loadedData[propName] != undefined) {
                        //console.log("It does contain a value! Let's set that to " + loadedData[propName]);
                        settingsContainer.setProperty(propName, loadedData[propName]);
                    }
                    var newValue = getProperty(propName);
                    if (oldValue !== newValue) {
                        component.propertyChanged(propName, newValue);
                    }
                }
            }
        }

        function saveSettings()
        {
            ensureContainer();
            var data = {};
            //console.log("Saving settings for " + component.name);
            for (var i = 0; i < component.persist.length; ++i) {
                var propName = component.persist[i];
                //console.log("Checking property " + propName);
                if (settingsContainer.hasProperty(propName)) {
                    data[propName] = settingsContainer.getProperty(propName);
                    //console.log("Adding property to container, value is " + data[propName]);
                }
            }
            //console.log("Got all the settings, data is " + data + " which when stringified this becomes " + JSON.stringify(data));
            settingsContainer.saveData("settings", JSON.stringify(data));
        }
        property QtObject settingsSaver: Timer {
            interval: 500
            repeat: false
            onTriggered: {
                _private.saveSettings();
            }
        }
    }
}
