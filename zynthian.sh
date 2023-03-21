#!/bin/bash
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Start Script
# 
# Start all services needed by zynthian and the zynthian UI
# 
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
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

# Throw up a splash screen while we load up the UI proper
if [ ! -p /tmp/mplayer-splash-control ]; then
    mkfifo /tmp/mplayer-splash-control
fi
mplayer -slave -input file=/tmp/mplayer-splash-control -noborder -ontop -geometry 50%:50% /usr/share/zynthbox-bootsplash/zynthbox-bootsplash.mkv -loop 0 &> /dev/null &
SPLASH_PID=$!

# Start Zynthian GUI & Synth Engine
export QT_QUICK_CONTROLS_MOBILE=1
export QT_QUICK_CONTROLS_STYLE=Zynthian-Plasma
export QT_FILE_SELECTORS=Plasma
export QT_QUICK_CONTROLS_STYLE_PATH=./qtquick-controls-style
export QT_IM_MODULE=qtvirtualkeyboard
#export QT_SCALE_FACTOR=1.2
#Qt5.11 didn't support this var yet
#export QT_QPA_SYSTEM_ICON_THEME=breeze
#workaround for the old kirigami version
export XDG_CURRENT_DESKTOP=kde
export QT_QPA_PLATFORMTHEME=generic
export XDG_DATA_DIRS=/usr/share

#HACK
rm ../config/keybinding.yaml

export QSG_RENDER_LOOP=threaded
export QT_SCALE_FACTOR=1
export QT_SCREEN_SCALE_FACTORS=1
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_QPA_PLATFORMTHEME=generic

if command -v kwin_x11 &> /dev/null; then
    kwin_x11&
    
    # Enable qml debuuger if ZYNTHBOX_DEBUG env variable is set
    if [ -z "$ZYNTHBOX_DEBUG" ]; then    
        export ZYNTHIAN_LOG_LEVEL=20
        
        python3 -X faulthandler ./bootlog_window.py &
        ./zynthian_qt_gui.py
    else
        export ZYNTHIAN_LOG_LEVEL=10
        extra_args=""

        if [ "$ZYNTHBOX_DEBUG" = "block" ]; then
            extra_args="$extra_args,block"
        fi

        python3 -X faulthandler ./bootlog_window.py &
        python3 -X faulthandler ./zynthian_qt_gui.py -qmljsdebugger=port:10002,$extra_args
    fi
    
    kill -9 $SPLASH_PID
    
    # If control reaches here it means the application exited.
    # Application should never exit by itself and should always be running.
    # Restart application
    systemctl restart jack2 zynthian
else        
    echo "ERROR: kwin was not installed. Exiting."
    kill -9 $SPLASH_PID
    exit 1
fi

#------------------------------------------------------------------------------
