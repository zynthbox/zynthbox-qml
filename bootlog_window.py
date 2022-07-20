import logging
import select
import sys
from pathlib import Path
from time import sleep


logging.basicConfig(format='%(levelname)s:%(module)s.%(funcName)s: %(message)s', stream=sys.stderr, level=logging.DEBUG)


if __name__ == "__main__":
    while not Path("/tmp/bootlog.fifo").exists():
        logging.debug("bootlog.fifo not found. Waiting")
        sleep(1)
        continue

    logging.debug("Found bootlog.fifo file. Reading.")

    with open("/tmp/bootlog.fifo", "r") as fifo:
        while True:
            data = fifo.readline()[:-1].strip()

            if data == "exit":
                logging.debug("Received exit command. Cleaning up and exiting")
                sys.exit(0)
            else:
                if len(data) > 0:
                    logging.debug(data)
