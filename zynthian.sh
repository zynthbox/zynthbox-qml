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

function backlight_on() {
    # Turn On Display Backlight
    #echo 0 > /sys/class/backlight/soc:backlight/bl_power
    #echo 0 > /sys/class/backlight/fb_ili9486/bl_power
    echo 0 > /sys/class/backlight/*/bl_power
}

function backlight_off() {
    # Turn Off Display Backlight
    #echo 1 > /sys/class/backlight/soc:backlight/bl_power
    #echo 1 > /sys/class/backlight/fb_ili9486/bl_power
    echo 1 > /sys/class/backlight/*/bl_power
}

function screensaver_off() {
    # Don't activate screensaver
    xset s off
    # Disable DPMS (Energy Star) features.
    xset -dpms
    # Don't blank the video device
    xset s noblank
}

function splash_zynthian() {
    if [ -c $FRAMEBUFFER ]; then
        cat $ZYNTHIAN_CONFIG_DIR/img/fb_zynthian_boot.raw > $FRAMEBUFFER
    fi
}

function splash_zynthian_error() {
    if [ -c $FRAMEBUFFER ]; then
        #Get the IP
        #zynthian_ip=`ip route get 1 | awk '{print $NF;exit}'`
        zynthian_ip=`ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q'`

        #Generate an error image with the IP ...
        img_fpath="$ZYNTHIAN_CONFIG_DIR/img/fb_zynthian_error.png"
        img_w=`identify -format '%w' $img_fpath`
        img_h=`identify -format '%h' $img_fpath`
        pos_x=$(expr $img_w \* 100 / 266)
        pos_y=$(expr $img_h \* 100 / 110)
        font_size=$(expr $img_w / 24)
        convert -pointsize $font_size -fill white -draw "text $pos_x,$pos_y \"IP: $zynthian_ip\"" $img_fpath $ZYNTHIAN_CONFIG_DIR/img/fb_zynthian_error_ip.png
        
        #Display error image
        xloadimage -fullscreen -onroot $ZYNTHIAN_CONFIG_DIR/img/fb_zynthian_error_ip.png
        #cat $ZYNTHIAN_CONFIG_DIR/img/fb_zynthian_error.raw > $FRAMEBUFFER
    fi
}

#------------------------------------------------------------------------------
# Main Program
#------------------------------------------------------------------------------

xsetroot -cursor blank_cursor.xbm blank_cursor.xbm

cd $ZYNTHIAN_UI_DIR

backlight_on
screensaver_off

while true; do
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
    #HACK 2
    mkdir -p /root/.local/share/plasma/desktoptheme/zynthian
    cp -auR zynthian-plasma-theme/* /root/.local/share/plasma/desktoptheme/zynthian/
    mkdir -p /root/.local/share/plasma/desktoptheme/zynthbox-new-theme
    cp -auR zynthbox-new-theme/* /root/.local/share/plasma/desktoptheme/zynthbox-new-theme/
    #cp zynthian_envars.sh ../config

    export QSG_RENDER_LOOP=threaded
    export QT_SCALE_FACTOR=1
    export QT_SCREEN_SCALE_FACTORS=1
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
    export QT_QPA_PLATFORMTHEME=generic
    
    ############################
    # FIXME : Temporarily default to debug mode
    export ZYNTHBOX_DEBUG=1
    ############################

    if command -v kwin_x11 &> /dev/null
    then
        kwin_x11&
    else
        echo "WARNING: kwin was not installed, falling back to matchbox - this will likely cause issues with some parts of the software (in particular for example modules which require xembed, such as norns)"
        matchbox-window-manager -use_titlebar no -use_cursor no -use_super_modal yes -use_dialog_mode free&
        #openbox&
    fi

    # Enable qml debuuger if ZYNTHBOX_DEBUG env variable is set
    if [ -z "$ZYNTHBOX_DEBUG" ]; then    
        export ZYNTHIAN_LOG_LEVEL=20
        ./zynthian_qt_gui.py
    else
        export ZYNTHIAN_LOG_LEVEL=10
        extra_args=""

        if [ "$ZYNTHBOX_DEBUG" = "block" ]; then
            extra_args="$extra_args,block"
        fi

        python3 -X faulthandler ./zynthian_qt_gui.py -qmljsdebugger=port:10002,$extra_args
    fi

    status=$?

    # Proccess output status
    case $status in
        0)
            splash_zynthian
            poweroff
            break
        ;;
        100)
            splash_zynthian
            reboot
            break
        ;;
        101)
            splash_zynthian
            backlight_off
            break
        ;;
        102)
            splash_zynthian
            sleep 1
        ;;
        *)
            splash_zynthian_error
            sleep 3
        ;;
    esac

    kill -9 $SPLASH_PID
done

#------------------------------------------------------------------------------
