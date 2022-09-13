#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian LED Configuration : A page to configure LED colors
#
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
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

from PySide2.QtCore import Property, QTimer, Signal, Slot

import logging

import rpi_ws281x

from . import zynthian_qt_gui_base


class zynthian_gui_led_config(zynthian_qt_gui_base.ZynGui):
    """
    A Helper class that sets correct led color per button as per current state

    Button id map :
    0 : Menu
    1 : 1
    2 : 2
    3 : 3
    4 : 4
    5 : 5
    6 : 6
    7 : FX
    8 : Under Screen Button 1
    9 : Under Screen Button 2
    10 : Under Screen Button 3
    11 : Under Screen Button 4
    12 : Under Screen Button 5
    13 : ALT
    14 : RECORD
    15 : PLAY
    16 : SAVE
    17 : STOP
    18 : BACK/NO
    19 : UP
    20 : SELECT/YES
    21 : LEFT
    22 : BOTTOM
    23 : RIGHT
    24 : MASTER
    """
    def __init__(self, parent=None):
        super(zynthian_gui_led_config, self).__init__(parent)

        self.led_color_off = rpi_ws281x.Color(0, 0, 0)
        self.led_color_blue = rpi_ws281x.Color(0, 50, 200)
        self.led_color_green = rpi_ws281x.Color(0, 255, 0)
        self.led_color_red = rpi_ws281x.Color(247, 124, 124)
        self.led_color_yellow = rpi_ws281x.Color(255, 235, 59)
        self.led_color_purple = rpi_ws281x.Color(142, 36, 170)
        self.led_color_light = self.led_color_blue
        self.led_color_active = self.led_color_green
        self.led_color_admin = self.led_color_red

        self.button_color_map = {}

        # Initialise all button with off color and not blinking
        for i in range(25):
            self.button_color_map[i] = {
                'color': self.led_color_blue,
                'blink': False
            }

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def update_button_colors(self):
        try:
            channel = None
            if self.zyngui.sketchpad.song is not None:
                channel = self.zyngui.sketchpad.song.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)

            # Menu
            if self.zyngui.modal_screen is None and self.zyngui.active_screen == "main":
                self.button_color_map[0] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[0] = {
                    'color': self.led_color_light,
                    'blink': False
                }

            # Light up 1-5 buttons as per opened screen / bottomBar
            for i in range(1, 6):
                # If left sidebar is active, blink selected part buttons for sample modes or blink filled clips for loop mode
                # This is global (i.e. for all screens)
                if self.zyngui.leftSidebarActive:
                    # If slots synths bar is active, light up filled cells otherwise turn off led
                    if channel is not None and channel.channelAudioType == "synth":
                        if channel.chainedSounds[i - 1] > -1 and \
                                channel.checkIfLayerExists(channel.chainedSounds[i - 1]):
                            self.button_color_map[i] = {
                                'color': self.led_color_red,
                                'blink': True
                            }
                        else:
                            self.button_color_map[i] = {
                                'color': self.led_color_blue,
                                'blink': False
                            }

                        continue

                    # If slots samples bar is active, light up filled cells otherwise turn off led
                    if channel is not None and channel.channelAudioType in ["sample-trig", "sample-slice"]:
                        if channel.samples[i - 1].path is not None:
                            self.button_color_map[i] = {
                                'color': self.led_color_yellow,
                                'blink': True
                            }
                        else:
                            self.button_color_map[i] = {
                                'color': self.led_color_blue,
                                'blink': False
                            }

                        continue

                    # If channel is in loop mode, light slot having a clip green, otherwise turn off
                    if channel is not None and channel.channelAudioType == "sample-loop":
                        clip = channel.getClipsModelByPart(i-1).getClip(self.zyngui.sketchpad.song.scenesModel.selectedTrackIndex)

                        if clip is not None and clip.path is not None and len(clip.path) > 0:
                            self.button_color_map[i] = {
                                'color': self.led_color_green,
                                'blink': True
                            }
                        else:
                            self.button_color_map[i] = {
                                'color': self.led_color_blue,
                                'blink': False
                            }

                        continue

                    # If sound combinator is active, light up filled cells with green color otherwise display blue color
                    if self.zyngui.soundCombinatorActive:
                        if channel is not None and \
                                (i - 1) == channel.selectedSlotRow:
                            # Set active color to selected sound row when combinator is open
                            self.button_color_map[i] = {
                                'color': self.led_color_active,
                                'blink': False
                            }
                        else:
                            self.button_color_map[i] = {
                                'color': self.led_color_light,
                                'blink': False
                            }

                        continue

                    # If none of the above conditions were true, light up button with blue color
                    self.button_color_map[i] = {
                        'color': self.led_color_light,
                        'blink': False
                    }

                    continue

                # If main page is open, light buttons as per selected tab in order : Modules(modules), Apps(appimages), Sessions(sessions), Templates(templates), Discover(discover)
                if self.zyngui.active_screen == "main":
                    tabs = ["modules", "appimages", ("sessions", "sessions-versions"), "templates", "discover"]
                    if self.zyngui.main.visibleCategory == tabs[i-1] or self.zyngui.main.visibleCategory in tabs[i-1]:
                        self.button_color_map[i] = {
                            'color': self.led_color_green,
                            'blink': False
                        }
                    else:
                        self.button_color_map[i] = {
                            'color': self.led_color_blue,
                            'blink': False
                        }

                    continue

                partClip = self.zyngui.sketchpad.song.getClipByPart(channel.id, self.zyngui.sketchpad.song.scenesModel.selectedTrackIndex, i - 1)

                if channel is not None and partClip.enabled:
                    if channel.channelAudioType == "synth":
                        self.button_color_map[i] = {
                            'color': self.led_color_red,
                            'blink': False
                        }
                    elif channel.channelAudioType in ["sample-trig", "sample-slice"]:
                        self.button_color_map[i] = {
                            'color': self.led_color_yellow,
                            'blink': False
                        }
                    elif channel.channelAudioType == "sample-loop":
                        self.button_color_map[i] = {
                            'color': self.led_color_green,
                            'blink': False
                        }
                    elif channel.channelAudioType == "external":
                        self.button_color_map[i] = {
                            'color': self.led_color_purple,
                            'blink': False
                        }
                else:
                    self.button_color_map[i] = {
                        'color': self.led_color_blue,
                        'blink': False
                    }

            # 7 : FX Button
            if self.zyngui.active_screen == "main":
                # If main page is open, color it blue
                self.button_color_map[7] = {
                    'color': self.led_color_blue,
                    'blink': False
                }
            elif channel is not None and channel.channelAudioType == "synth":
                if self.zyngui.leftSidebarActive:
                    self.button_color_map[7] = {
                        'color': self.led_color_red,
                        'blink': True
                    }
                else:
                    self.button_color_map[7] = {
                        'color': self.led_color_red,
                        'blink': False
                    }
            elif channel is not None and channel.channelAudioType in ["sample-trig", "sample-slice"]:
                if self.zyngui.leftSidebarActive:
                    self.button_color_map[7] = {
                        'color': self.led_color_yellow,
                        'blink': True
                    }
                else:
                    self.button_color_map[7] = {
                        'color': self.led_color_yellow,
                        'blink': False
                    }
            elif self.zyngui.slotsBarFxActive:
                if self.zyngui.leftSidebarActive:
                    self.button_color_map[7] = {
                        'color': self.led_color_blue,
                        'blink': True
                    }
                else:
                    self.button_color_map[7] = {
                        'color': self.led_color_blue,
                        'blink': False
                    }
            elif channel is not None and channel.channelAudioType == "sample-loop":
                if self.zyngui.leftSidebarActive:
                    self.button_color_map[7] = {
                        'color': self.led_color_green,
                        'blink': True
                    }
                else:
                    self.button_color_map[7] = {
                        'color': self.led_color_green,
                        'blink': False
                    }
            elif channel is not None and channel.channelAudioType == "external":
                if self.zyngui.leftSidebarActive:
                    self.button_color_map[7] = {
                        'color': self.led_color_purple,
                        'blink': True
                    }
                else:
                    self.button_color_map[7] = {
                        'color': self.led_color_purple,
                        'blink': False
                    }
            else:
                if self.zyngui.leftSidebarActive:
                    self.button_color_map[7] = {
                        'color': self.led_color_blue,
                        'blink': True
                    }
                else:
                    self.button_color_map[7] = {
                        'color': self.led_color_blue,
                        'blink': False
                    }

            # Under screen button 1
            if self.zyngui.modal_screen is None and self.zyngui.active_screen == "sketchpad":
                self.button_color_map[8] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[8] = {
                    'color': self.led_color_light,
                    'blink': False
                }

            # Under screen button 2
            if self.zyngui.modal_screen == "playgrid":
                self.button_color_map[9] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[9] = {
                    'color': self.led_color_light,
                    'blink': False
                }

            # Under screen button 3
            if self.zyngui.modal_screen is None and self.zyngui.active_screen in ["layers_for_channel", "bank", "preset"]:
                self.button_color_map[10] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[10] = {
                    'color': self.led_color_light,
                    'blink': False
                }

            # Under screen button 4
            if self.zyngui.modal_screen == "song_arranger":
                self.button_color_map[11] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[11] = {
                    'color': self.led_color_light,
                    'blink': False
                }

            # Under screen button 5
            if self.zyngui.modal_screen == "admin":
                self.button_color_map[12] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[12] = {
                    'color': self.led_color_light,
                    'blink': False
                }

            # ALT button
            self.button_color_map[13] = {
                'color': self.led_color_light,
                'blink': False
            }

            # Recording Button
            if not self.zyngui.sketchpad.isRecording:
                self.button_color_map[14] = {
                    'color': self.led_color_light,
                    'blink': False
                }
            else:
                self.button_color_map[14] = {
                    'color': self.led_color_red,
                    'blink': False
                }

            # Play button
            if self.zyngui.sketchpad.isMetronomeRunning:
                self.button_color_map[15] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[15] = {
                    'color': self.led_color_light,
                    'blink': False
                }

            # Save button
            if self.zyngui.sketchpad.clickChannelEnabled:
                self.button_color_map[16] = {
                    'color': self.led_color_blue,
                    'blink': True
                }
            else:
                self.button_color_map[16] = {
                    'color': self.led_color_blue,
                    'blink': False
                }

            # Stop button
            self.button_color_map[17] = {
                'color': self.led_color_blue,
                'blink': False
            }

            # Back/No button
            self.button_color_map[18] = {
                'color': self.led_color_red,
                'blink': False
            }

            # Up button
            self.button_color_map[19] = {
                'color': self.led_color_light,
                'blink': False
            }

            # Select/Yes button
            self.button_color_map[20] = {
                'color': self.led_color_green,
                'blink': False
            }

            # Left Button
            self.button_color_map[21] = {
                'color': self.led_color_light,
                'blink': False
            }

            # Bottom Button
            self.button_color_map[22] = {
                'color': self.led_color_light,
                'blink': False
            }

            # Right Button
            self.button_color_map[23] = {
                'color': self.led_color_light,
                'blink': False
            }

            # Master Button
            if self.zyngui.globalPopupOpened:
                self.button_color_map[24] = {
                    'color': self.led_color_active,
                    'blink': False
                }
            else:
                self.button_color_map[24] = {
                    'color': self.led_color_light,
                    'blink': False
                }

        except Exception as e:
            logging.error(e)
