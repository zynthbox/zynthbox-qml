import logging
import os
import sys
from pathlib import Path
from PySide2.QtCore import Property, QObject, QTimer, Qt, Signal
from PySide2.QtGui import QCursor, QGuiApplication, QPixmap
from PySide2.QtQml import QQmlApplicationEngine


logging.basicConfig(format='%(levelname)s:%(module)s.%(funcName)s: %(message)s', stream=sys.stderr, level=logging.DEBUG)


class BootLogInterface(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        self.__boot_log = ""
        self.__boot_log_file = None

        self.check_boot_log_timer = QTimer()
        self.check_boot_log_timer.setInterval(10)
        self.check_boot_log_timer.setSingleShot(True)
        self.check_boot_log_timer.timeout.connect(self.check_boot_log_timer_timeout)
        self.check_boot_log_timer.start()

    def check_boot_log_timer_timeout(self):
        if not Path("/tmp/bootlog.fifo").exists():
            logging.debug("bootlog.fifo not found. Waiting")
        else:
            if self.__boot_log_file is None:
                self.__boot_log_file = open("/tmp/bootlog.fifo", "r")

            data = self.__boot_log_file.readline()[:-1].strip()

            if data == "exit":
                logging.debug("Received exit command. Cleaning up and exiting")
                sys.exit(0)
            elif len(data) > 0:
                self.bootLog = data

        self.check_boot_log_timer.start()

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

