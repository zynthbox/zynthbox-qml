import sys
from PySide2.QtCore import QObject, QByteArray, Signal, Property, Slot, QTimer, QStringListModel, Qt
from PySide2.QtGui import QGuiApplication, QIcon
from PySide2.QtQml import QQmlApplicationEngine
from pathlib import Path
import Zynthbox
import os
import signal


class ProcessWrapperTest(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        self.__consoleOutput = []
        self.__cmdInProgress = False
        self.p = Zynthbox.ProcessWrapper(self)
        self.p.standardOutput.connect(self.handleStandardOutput)
        self.p.standardError.connect(self.handleStandardError)
        self.p.stateChanged.connect(self.handleStateChanged)
        self.appendConsoleOutput("--- Created process wrapper, now starting process")
        self.appendConsoleOutput("jalv -n synthv1-py http://synthv1.sourceforge.net/lv2")
        self.p.start("jalv", ["-n", "synthv1-py", "http://synthv1.sourceforge.net/lv2"])
        self.appendConsoleOutput("--- Process started")

    @Slot()
    def handleStateChanged(self):
        self.appendConsoleOutput(f"--- ProcessWrapper state is now {self.p.state()}\n")
        if self.p.state() == Zynthbox.ProcessWrapper.ProcessState.NotRunningState:
            app.quit()

    @Slot(str)
    def sendCommandToProcess(self, cmd):
        def task():
            theResult = self.p.call(QByteArray(bytearray(f"{cmd}\n", "utf-8")), "\n> ")
            self.appendConsoleOutput(f"--- PROC OUTPUT BEGIN\n{theResult}\n--- PROC OUTPUT END")
            self.cmdInProgress = False
        self.appendConsoleOutput(cmd)
        self.cmdInProgress = True
        QTimer.singleShot(0, task)

    @Slot(str)
    def handleStandardOutput(self, output):
        # self.appendConsoleOutput(f"--- STDOUT BEGIN\n{output}\n--- STDOUT END")
        pass

    @Slot(str)
    def handleStandardError(self, output):
        # self.appendConsoleOutput(f"--- STDERR BEGIN\n{output}\n--- STDERR END")
        pass

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
