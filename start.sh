#!/bin/bash
#******************************************************************************
# Zynthbox QML UI Startup Script
# 
# Startup script for zynthbox-qml
# 
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
# Copyright (C) 2021-2023 Anupam Basak <anupam.basak27@gmail.com>
#
#******************************************************************************
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
#******************************************************************************


#export ZYNTHIAN_LOG_LEVEL=10            # 10=DEBUG, 20=INFO, 30=WARNING, 40=ERROR, 50=CRITICAL
#export ZYNTHIAN_RAISE_EXCEPTIONS=0

#------------------------------------------------------------------------------
# Some Functions
#------------------------------------------------------------------------------

function load_config_env() {
    if [ -d "$ZYNTHIAN_CONFIG_DIR" ]; then
        source "$ZYNTHIAN_CONFIG_DIR/zynthian_envars.sh"
    else
        source "$ZYNTHIAN_SYS_DIR/scripts/zynthian_envars.sh"
    fi

    if [ ! -z "$ZYNTHIAN_SCRIPT_MIDI_PROFILE" ]; then
        source "$ZYNTHIAN_SCRIPT_MIDI_PROFILE"
    else
        source "$ZYNTHIAN_MY_DATA_DIR/midi-profiles/default.sh"
    fi

    if [ -f "$ZYNTHIAN_CONFIG_DIR/zynthian_custom_config.sh" ]; then
        source "$ZYNTHIAN_CONFIG_DIR/zynthian_custom_config.sh"
    fi
}

function screensaver_off() {
    # Don't activate screensaver
    xset s off
    # Disable DPMS (Energy Star) features.
    xset -dpms
    # Don't blank the video device
    xset s noblank
}

#------------------------------------------------------------------------------
# Main Program
#------------------------------------------------------------------------------

xsetroot -cursor blank_cursor.xbm blank_cursor.xbm

cd $ZYNTHIAN_UI_DIR

screensaver_off

#Load Config Environment
load_config_env

if [ -z ${XRANDR_ROTATE} ]; then
    echo "not rotating"
else
    xrandr -o $XRANDR_ROTATE
fi

# Start Zynthian GUI & Synth Engine

#HACK
rm ../config/keybinding.yaml

export QSG_RENDER_LOOP=threaded
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_IM_MODULE=qtvirtualkeyboard
export QT_QPA_PLATFORMTHEME=generic
export QT_QUICK_CONTROLS_MOBILE=1
export QT_QUICK_CONTROLS_STYLE=Plasma
export QT_SCALE_FACTOR=1
export QT_SCREEN_SCALE_FACTORS=1
export XDG_CURRENT_DESKTOP=kde
export XDG_DATA_DIRS=/usr/share

if command -v kwin_x11 &> /dev/null; then
    kwin_x11 &

    # Enable qml debuuger if ZYNTHBOX_DEBUG env variable is set
    if [ -z "$ZYNTHBOX_DEBUG" ]; then
        export ZYNTHIAN_LOG_LEVEL=20

        python3 -X faulthandler ./bootlog_window.py &
        python3 -X faulthandler./zynthian_qt_gui.py
    else
        export ZYNTHIAN_LOG_LEVEL=10
        extra_args=""

        if [ "$ZYNTHBOX_DEBUG" = "block" ]; then
            extra_args="$extra_args,block"
        fi

        python3 -X faulthandler ./bootlog_window.py &
        python3 -X faulthandler ./zynthian_qt_gui.py -qmljsdebugger=port:10002,$extra_args
    fi

    # If control reaches here it means the application exited.
    # Application should never exit by itself and should always be running.
    # Restart application
    systemctl restart jack2 mod-ttymidi zynthbox-qml
else
    echo "ERROR: kwin was not installed. Exiting."
    exit 1
fi

#------------------------------------------------------------------------------
