import sys
from PySide2.QtCore import QObject, QByteArray, Signal, Property, Slot, QTimer
from PySide2.QtGui import QGuiApplication, QIcon
from PySide2.QtQml import QQmlApplicationEngine
from pathlib import Path
from time import sleep
import Zynthbox
import os
import signal


class ProcessWrapperTest(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        self.__consoleOutput = []
        self.__cmdInProgress = True
        self.prompt = "\n> "
        self.p = Zynthbox.ProcessWrapper(self)
        self.p.stateChanged.connect(self.handleStateChanged)
        self.appendConsoleOutput("--- Created process wrapper")

    @Slot()
    def start(self):
        self.appendConsoleOutput("jalv -n synthv1-py http://synthv1.sourceforge.net/lv2")
        # self.p.start("stdbuf", ["-oL", "jalv", "-n", "synthv1-py", "http://synthv1.sourceforge.net/lv2"])
        self.p.start("jalv", ["-n", "synthv1-py", "http://synthv1.sourceforge.net/lv2"])
        self.appendConsoleOutput("--- Process started")
        # self.p.waitForOutput(self.prompt)
        # self.appendConsoleOutput(f"--- PROCESS START OUTPUT BEGIN\n{self.p.getStandardOutput()}\n--- PROCESS START OUTPUT END")
        self.cmdInProgress = False

    @Slot()
    def handleStateChanged(self):
        self.appendConsoleOutput(f"--- ProcessWrapper state is now {self.p.state()}\n")
        if self.p.state() == Zynthbox.ProcessWrapper.ProcessState.NotRunningState:
            app.quit()

    @Slot(str)
    def sendCommandToProcess(self, cmd):
        def task():
            self.p.send(QByteArray(bytearray(f"{cmd}\n", "utf-8")))
            self.p.waitForOutput(self.prompt)
            self.appendConsoleOutput(f"--- PROC OUTPUT BEGIN\n{self.p.getStandardOutput()}\n--- PROC OUTPUT END")
            self.cmdInProgress = False
        if cmd == "clear":
            self.__consoleOutput = []
            self.consoleOutputChanged.emit()
        else:
            self.appendConsoleOutput(cmd)
            self.cmdInProgress = True
            QTimer.singleShot(0, task)

    def get_consoleOutput(self):
        return self.__consoleOutput
    def appendConsoleOutput(self, data):
        self.__consoleOutput.append(data)
        self.consoleOutputChanged.emit()
    consoleOutputChanged = Signal()
    consoleOutput = Property("QVariantList", get_consoleOutput, notify=consoleOutputChanged)

    def get_cmdInProgress(self):
        return self.__cmdInProgress
    def set_cmdInProgress(self, val):
        self.__cmdInProgress = val
        self.cmdInProgressChanged.emit()
    cmdInProgressChanged = Signal()
    cmdInProgress = Property(bool, get_cmdInProgress, set_cmdInProgress, notify=cmdInProgressChanged)


signal.signal(signal.SIGINT, signal.SIG_DFL)


if __name__ == "__main__":
    app = QGuiApplication()
    engine = QQmlApplicationEngine()
    processWrapperTest = ProcessWrapperTest(engine)

    QIcon.setThemeName("breeze")
    engine.rootContext().setContextProperty("app", processWrapperTest)
    engine.load(os.fspath(Path(__file__).resolve().parent / "ProcessWrapperTest.qml"))
    sys.exit(app.exec_())
