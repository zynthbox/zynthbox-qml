import sys
from PySide2.QtCore import QByteArray, QGuiApplication, QQmlApplicationEngine, Slot, QTimer, QStringListModel
import Zynthbox


class ProcessWrapperTest(QObject):
    def __init__(self):
        self.console_output = []
        self.p = Zynthbox.ProcessWrapper(self)
        self.p.standardOutput.connect(handleStandardOutput)
        self.p.standardError.connect(handleStandardError)
        self.p.stateChanged.connect(handleStateChanged)
        self.appendConsoleOutput("--- Created process wrapper, now starting process")
        self.p.start("jalv", ["-n", "synthv1-py", "http://synthv1.sourceforge.net/lv2"])
        self.appendConsoleOutput("--- Process started")

    @Slot()
    def handleStateChanged():
        self.appendConsoleOutput(f"--- ProcessWrapper state is now {p.state()}\n")
        if p.state() == Zynthbox.ProcessWrapper.ProcessState.NotRunningState:
            app.quit()

    @Slot()
    def talkToProcess():
        self.appendConsoleOutput("--- Call a couple of functions - first a non-blocking one: set 15 1")
        p.send(QByteArray(b"set 15 1\n"))
        self.appendConsoleOutput("--- Non-blocking function (without output) called - now calling a blocking function (which must return some output)")
        theResult = p.call(QByteArray(b"preset file:///zynthian/zynthian-data/presets/lv2/synthv1_392Synthv1Patches.presets.lv2/392Synthv1Patches_NoizeExport01.ttl\n"))
        self.appendConsoleOutput(f"--- The result data from the blocking call was:\n--- START RESULT ---\n{theResult}\n--- END RESULT ---")
        p.stop()


    @Slot(str)
    def handleStandardOutput(output):
        self.appendConsoleOutput(f"--- STDOUT BEGIN\n{output}\n--- STDOUT END")
        # We know the last thing output by jalv on startup is the alsa
        # playback configuration, we can use that here. Other tools will
        # require other estimates, but that's out test case here, and it
        # shows how to use that knowledge to perform actions
        if output.startswith("ALSA: use") and output.endswith("periods for playback\n"):
            talkToProcess()

    @Slot(str)
    def handleStandardError(output):
        self.appendConsoleOutput(f"--- STDERR BEGIN\n{output}\n--- STDERR END")
        # if "Comm buffers" in output and "Update rate: " in output:

    def get_consoleOutput(self):
        return self.console_output
    def appendConsoleOutput(self, data):
        self.console_output.append(data)
        self.consoleOutputChanged.emit()
    consoleOutputChanged = Signal()
    consoleOutput = Property("QVariantList", get_consoleOutput, notify=consoleOutputChanged)

if __name__ == "__main__":
    app = QGuiApplication()
    engine = QQmlApplicationEngine()
    processWrapperTest = ProcessWrapperTest(app)

    engine.rootContext().setContextProperty("app", processWrapperTest)
    engine.load(os.fspath(Path(__file__).resolve().parent / "ProcessWrapperTest.qml"))
    sys.exit(app.exec_())
