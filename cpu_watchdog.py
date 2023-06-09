#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# CPU State watchdog (nominally undervoltage and overtemp states)
#
# Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>
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
#********

import os
import sys
import time
import logging
from pathlib import Path
from subprocess import check_output

logging.basicConfig(format='%(levelname)s:%(module)s.%(funcName)s: %(message)s', stream=sys.stderr, level=logging.DEBUG)

if __name__ == "__main__":
    #os.sched_setaffinity(os.getpid(), [3])
    watchdog_data = ""
    watchdog_fifo = None
    lastOvertempState = False
    lastUndervoltageState = False
    currentOvertempState = False
    currentUndervoltageState = False
    while True:
        if Path("/tmp/cpu_watchdog.fifo").exists():
            if watchdog_fifo is None:
                watchdog_fifo = open("/tmp/cpu_watchdog.fifo", "w")

            try:
                # Get ARM flags
                res = check_output(("vcgencmd", "get_throttled")).decode(
                    "utf-8", "ignore"
                )
                thr = int(res[12:], 16)
                if thr & 0x1:
                    currentUndervoltageState = True
                else:
                    currentUndervoltageState = False
                if thr & (0x4 | 0x2):
                    currentOvertempState = True
                else:
                    currentOvertempState = False

                # Now write out an update, if there is an update
                if currentOvertempState != lastOvertempState:
                    watchdog_fifo.write(f"overtemp {currentOvertempState}\n")
                    lastOvertempState = currentOvertempState
                if currentUndervoltageState != lastUndervoltageState:
                    watchdog_fifo.write(f"undervoltage {currentUndervoltageState}\n")
                    lastUndervoltageState = currentUndervoltageState

            except Exception as e:
                logging.error(e)

        time.sleep(0.3)
    if watchdog_fifo:
        watchdog_fifo.close()
