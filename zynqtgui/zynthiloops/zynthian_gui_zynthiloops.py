#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian PlayGrid: A page to play ntoes with buttons
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
import queue
import jack
import soundfile as sf
import logging

from PySide2.QtCore import Property, QObject, Signal, Slot
from PySide2.QtQml import qmlRegisterType

from .zynthiloops_clip import zynthiloops_clip
from .zynthiloops_part import zynthiloops_part
from .zynthiloops_parts_model import zynthiloops_parts_model
from .zynthiloops_song import zynthiloops_song
from .zynthiloops_track import ZynthiLoopsTrack
from .zynthiloops_tracks_model import ZynthiLoopsTracksModel
from .. import zynthian_qt_gui_base


class zynthian_gui_zynthiloops(zynthian_qt_gui_base.ZynGui):
    __track_counter__ = 0
    __buffer_size__ = 20
    __client_name__ = "ZynthiLoops"

    def __init__(self, parent=None):
        super(zynthian_gui_zynthiloops, self).__init__(parent)

        self.__model__ = ZynthiLoopsTracksModel(self)
        self.__parts__ = zynthiloops_parts_model(self)
        self.__q__ = queue.Queue(maxsize=self.__buffer_size__)
        self.__client__ = jack.Client(self.__client_name__)
        self.__blocksize__ = self.__client__.blocksize
        self.__samplerate__ = self.__client__.samplerate

        self.__register_qml_modules__()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def print_error(self, *args):
        logging.error(*args)

    def xrun(self, delay):
        logging.info("An xrun occured, increase JACK's period size?")

    def shutdown(self, status, reason):
        logging.info('JACK shutdown!')
        logging.info('status:', status)
        logging.info('reason:', reason)

    def stop_callback(self, msg=''):
        if msg:
            logging.error(msg)
        for port in self.__client__.outports:
            port.get_array().fill(0)

        logging.info("Stop Callback")

    def process(self, frames):
        if frames != self.__blocksize__:
            self.stop_callback('blocksize must not be changed, I quit!')
        try:
            data = self.__q__.get_nowait()
        except queue.Empty:
            self.stop_callback('Buffer is empty: increase buffersize?')
        if data is None:
            self.stop_callback()  # Playback is finished
        for channel, port in zip(data.T, self.__client__.outports):
            port.get_array()[:] = channel

    def __register_qml_modules__(self):
        qmlRegisterType(zynthiloops_song, 'ZynthiLoops', 1, 0, "Song")
        qmlRegisterType(zynthiloops_clip, 'ZynthiLoops', 1, 0, "Clip")
        qmlRegisterType(zynthiloops_part, 'ZynthiLoops', 1, 0, "Part")

    @Signal
    def __model_changed__(self):
        pass

    @Signal
    def __parts_changed__(self):
        pass

    @Property(QObject, notify=__model_changed__)
    def model(self):
        return self.__model__

    @Property(QObject, notify=__parts_changed__)
    def parts(self):
        return self.__parts__

    @Slot(None)
    def addTrack(self):
        self.__track_counter__ += 1
        self.__model__.add_track(ZynthiLoopsTrack(self.__track_counter__))

    @Slot(None)
    def playWav(self, loop=True):
        try:
            self.__client__.set_xrun_callback(self.xrun)
            self.__client__.set_shutdown_callback(self.shutdown)
            self.__client__.set_process_callback(self.process)

            with sf.SoundFile("/zynthian/zynthian-my-data/capture/test.wav") as f:
                for ch in range(f.channels):
                    self.__client__.outports.register('out_{0}'.format(ch + 1))
                block_generator = f.blocks(blocksize=self.__blocksize__, dtype='float32',
                                           always_2d=True, fill_value=0)
                for _, data in zip(range(self.__buffer_size__), block_generator):
                    self.__q__.put_nowait(data)  # Pre-fill queue
                with self.__client__:
                    target_ports = self.__client__.get_ports(
                        is_physical=True, is_input=True, is_audio=True)
                    if len(self.__client__.outports) == 1 and len(target_ports) > 1:
                        # Connect mono file to stereo output
                        self.__client__.outports[0].connect(target_ports[0])
                        self.__client__.outports[0].connect(target_ports[1])
                    else:
                        for source, target in zip(self.__client__.outports, target_ports):
                            source.connect(target)

                    timeout = self.__blocksize__ * self.__buffer_size__ / self.__samplerate__
                    for data in block_generator:
                        self.__q__.put(data, timeout=timeout)
                    self.__q__.put(None, timeout=timeout)  # Signal end of file
        except (queue.Full):
            # A timeout occured, i.e. there was an error in the callback
            logging.error("Queue Full")
        except Exception as e:
            logging.error(type(e).__name__ + ': ' + str(e))

    # @partsCount.setter
    # def __parts_setter__(self, parts_count):
    #     self.__parts_count__ = parts_count
