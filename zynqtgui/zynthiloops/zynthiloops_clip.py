#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthiloops Clip: An object to store clip information for a track
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

import logging
import queue

import jack
import soundfile as sf

from PySide2.QtCore import Property, QObject, Signal, Slot


class zynthiloops_clip(QObject):
    __client_name__ = "ZynthiLoops"
    __buffer_size__ = 20
    __length__ = 1
    __row_index__ = 0
    __col_index__ = 0
    __is_playing__ = False

    def __init__(self, parent=None):
        super(zynthiloops_clip, self).__init__(parent)

        self.__q__ = queue.Queue(maxsize=self.__buffer_size__)
        self.__client__ = jack.Client(self.__client_name__)
        self.__blocksize__ = self.__client__.blocksize
        self.__samplerate__ = self.__client__.samplerate

        self.__client__.set_xrun_callback(self.xrun)
        self.__client__.set_shutdown_callback(self.shutdown)
        self.__client__.set_process_callback(self.process)

        with sf.SoundFile("/zynthian/zynthian-my-data/capture/test.wav") as f:
            for ch in range(f.channels):
                self.__client__.outports.register('out_{0}'.format(ch + 1))

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
            # self.stop_callback()  # Playback is finished
            self.__q__.queue.clear()

        for channel, port in zip(data.T, self.__client__.outports):
            port.get_array()[:] = channel

    @Signal
    def length_changed(self):
        pass

    @Signal
    def row_index_changed(self):
        pass

    @Signal
    def col_index_changed(self):
        pass

    @Signal
    def __is_playing_changed__(self):
        pass

    @Property(bool, constant=True)
    def playable(self):
        return True

    @Property(bool, constant=True)
    def recordable(self):
        return True

    @Property(bool, constant=True)
    def clearable(self):
        return True

    @Property(bool, constant=True)
    def deletable(self):
        return False

    @Property(bool, notify=__is_playing_changed__)
    def isPlaying(self):
        return self.__is_playing__

    @isPlaying.setter
    def __set_is_playing__(self, is_playing: bool):
        self.__is_playing__ = is_playing
        self.__is_playing_changed__.emit()

    @Property(int, notify=length_changed)
    def length(self):
        return self.__length__

    @length.setter
    def set_length(self, length: int):
        self.__length__ = length
        self.length_changed.emit()

    @Property(int, notify=row_index_changed)
    def row(self):
        return self.__row_index__

    @row.setter
    def set_row_index(self, index):
        self.__row_index__ = index
        self.row_index_changed.emit()

    @Property(int, notify=col_index_changed)
    def col(self):
        return self.__col_index__

    @col.setter
    def set_col_index(self, index):
        self.__col_index__ = index
        self.col_index_changed.emit()

    @Property(str, constant=True)
    def name(self):
        return f"Clip {self.__row_index__ + 1}"

    @Slot(None)
    def playWav(self, loop=True):
        self.__is_playing__ = True
        self.__is_playing_changed__.emit()

        with self.__q__.mutex:
            self.__q__.queue.clear()

        try:
            with sf.SoundFile("/zynthian/zynthian-my-data/capture/test.wav") as f:
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
        finally:
            self.__is_playing__ = False
            self.__is_playing_changed__.emit()
