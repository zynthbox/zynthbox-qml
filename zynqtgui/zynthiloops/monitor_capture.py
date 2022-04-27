from time import sleep

import jack
import logging
import threading
import numpy as np
import math

client = jack.Client('zynthiloops_monitor')
port = client.inports.register("a")
event = threading.Event()

# CHANNEL_A = 0
# CHANNEL_B = 1
# CHANNEL_ALL = 2
#
# g_fPeak = [0.0, 0.0]
# g_fDamped = [0.0, 0.0, 0.0]
# g_fDampingFactor = 0
# currentLeveldB = 0.0
# prevLeveldB = 0.0


# def dbToGain(db):
#     return 10.0**(db/20.0)
#
#
# def gainToDb(gain):
#     if gain > 0.0:
#         return 20.0 * math.log10(gain)
#     else:
#         return -100.0


def convertToDBFS(raw):
    if raw <= 0:
        return -200
    fValue = 20 * math.log10(raw)
    if fValue < -200:
        fValue = -200
    return fValue


# def getPeakRaw(channel):
#     fPeak = 0
#     if channel < CHANNEL_ALL:
#         fPeak = g_fPeak[channel]
#         g_fPeak[channel] = 0
#     elif channel == CHANNEL_ALL:
#         fPeak = g_fPeak[CHANNEL_A]
#         g_fPeak[CHANNEL_A] = 0
#         if fPeak < g_fPeak[CHANNEL_B]:
#             fPeak = g_fPeak[CHANNEL_B]
#         g_fPeak[CHANNEL_B] = 0
#     return fPeak
#
#
# def getPeak(channel):
#     fPeak = 0
#     if channel <= CHANNEL_ALL:
#         fPeak = getPeakRaw(channel)
#         if fPeak < g_fDamped[channel] * g_fDampingFactor:
#             fPeak = g_fDamped[channel] * g_fDampingFactor
#         if fPeak < 0.0:
#             fPeak = 0.0
#         g_fDamped[channel] = fPeak
#
#     return convertToDBFS(fPeak)


@client.set_process_callback
def process(frames):
    buf = np.frombuffer(port.get_buffer())
    raw_peak = 0

    for i in range(0, frames):
        try:
            sample = abs(buf[i])

            if sample > raw_peak:
                raw_peak = sample
        except:
            pass

    peak = raw_peak

    if peak < 0.0:
        peak = 0.0

    logging.debug(f"Peak : {convertToDBFS(peak)}")

    # buf = np.frombuffer(port.get_buffer())
    # maxValue = 2**16
    #
    # peak = np.abs(np.max(buf)-np.min(buf))/maxValue
    # logging.error(f"Peak : {convertToDBFS(peak*100)}")


with client:
    client.connect("system:capture_1", port.name)

    #while True:
        # prevLeveldB = currentLeveldB
        # currentLeveldB = getPeak(0)
        #
        # prevLevel = dbToGain(prevLeveldB)
        #
        # if prevLeveldB > currentLeveldB:
        #     currentLeveldB = gainToDb(prevLevel * 0.94)
        #
        # if currentLeveldB != prevLeveldB:
        #     logging.error(f"Peak : {currentLeveldB}")
        #
        # sleep(0.01)

    print('Press Ctrl+C to stop')
    try:
        event.wait()
    except KeyboardInterrupt:
        print('\nInterrupted by user')
