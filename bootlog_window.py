import logging
import os
import sys
import time
from pathlib import Path
from threading import Thread
from PySide2.QtCore import Property, QObject, Qt, Signal, Slot
from PySide2.QtGui import QCursor, QGuiApplication, QPixmap
from PySide2.QtQml import QQmlApplicationEngine


logging.basicConfig(format='%(levelname)s:%(module)s.%(funcName)s: %(message)s', stream=sys.stderr, level=logging.DEBUG)


class BootLogInterface(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        logging.error("Starting bootlog display")
        self.__boot_log = ""
        self.__boot_log_file = None

        self.__bootCompleted = False
        self.exit_flag = False
        logging.error("Setting thread")
        self.check_boot_log_thread = Thread(target=self.check_boot_log_timeout, args=())
        self.check_boot_log_thread.daemon = True # thread will exit with the program
        logging.error("Starting thread")
        self.check_boot_log_thread.start()

    def check_boot_log_timeout(self):
        while not self.exit_flag:
            # Skip reading until bootlog.fifo file is found
            if Path("/tmp/bootlog.fifo").exists():
                if self.__boot_log_file is None:
                    self.__boot_log_file = open("/tmp/bootlog.fifo", "r")

                data = self.__boot_log_file.readline()[:-1].strip()

                if data.startswith("command:"):
                    if data == "command:exit":
                        logging.debug("Received exit command. Cleaning up and exiting")
                        self.bootLog = "Shutting down"
                        self.exit_flag = True
                        QGuiApplication.quit()
                    elif data == "command:play-extro":
                        logging.debug("Received play-extro command. Playing extro video")
                        self.bootLog = ""
                        self.playExtroAndHide.emit()
                    elif data == "command:show":
                        self.showBootlog.emit()
                    elif data == "command:hide" and self.bootCompleted:
                        self.bootLog = ""
                        self.hideBootlog.emit()
                elif len(data) > 0:
                    self.bootLog = data
            time.sleep(0.1)
        if self.__boot_log_file is not None:
            self.__boot_log_file.close()

    ### Property bootLog
    def get_bootLog(self):
        return self.__boot_log

    def set_bootLog(self, value):
        if self.__boot_log != value:
            logging.debug(f"Setting bootLog : {value}")
            self.__boot_log = value
            self.bootLogChanged.emit()

    bootLogChanged = Signal()

    bootLog = Property(str, get_bootLog, set_bootLog, notify=bootLogChanged)
    ### END Property bootLog

    ### Property bootCompleted
    def get_bootCompleted(self):
        return self.__bootCompleted
    def set_bootCompleted(self, bootCompleted):
        if self.__bootCompleted != bootCompleted:
            self.__bootCompleted = bootCompleted
            self.bootCompletedChanged.emit()
    bootCompletedChanged = Signal()
    bootCompleted = Property(bool, get_bootCompleted, set_bootCompleted, notify=bootCompletedChanged)
    ### END Property bootCompleted

    playExtroAndHide = Signal()
    showBootlog = Signal()
    hideBootlog = Signal()


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    bootLogInterface = BootLogInterface(app)

    nullCursor = QPixmap(16, 16)
    nullCursor.fill(Qt.transparent)
    app.setOverrideCursor(QCursor(nullCursor))

    engine.rootContext().setContextProperty("bootLogInterface", bootLogInterface)
    engine.load(os.fspath(Path(__file__).resolve().parent / "qml-ui/BootLogWindow.qml"))

    sys.exit(app.exec_())
