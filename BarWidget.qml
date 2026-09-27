pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar button for Oma Dual Font.
//
// It owns the icon, the two current family names behind the tooltip, and the
// popup's lifecycle. Everything that actually touches a config file lives in
// bin/oma-dual-font, so the widget stays a view over a CLI that works on its
// own from a shell.
BarWidget {
  id: root
  moduleName: "io.github.fromchaoscomesclarity.oma-dual-font"

  readonly property Item button: buttonItem

  // Qt hands back a file:// URL; Process wants a plain path.
  readonly property string cli: Qt.resolvedUrl("bin/oma-dual-font").toString().replace(/^file:\/\//, "")

  property string systemFont: ""
  property string terminalFont: ""

  function refresh() {
    systemProc.running = true
    terminalProc.running = true
  }

  // The panel is created by a Loader, so the host properties it binds against
  // have to be pushed in once it exists, and again whenever the bar hands us
  // new ones.
  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("hostWidget" in target) target.hostWidget = root
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
  }

  // --- popup lifecycle, as the bar host expects it -------------------------

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function togglePanel() { toggle() }
  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: buttonItem.implicitWidth
  implicitHeight: barSize

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Component.onCompleted: {
    refresh()
    // The hook is what stops omarchy-font-set dragging the terminal along, so
    // the plugin is not actually working without it. Installing is idempotent
    // and only writes when the content differs.
    hookProc.running = true
  }

  BarIconButton {
    id: buttonItem
    anchors.fill: parent
    bar: root.bar
    text: ""
    tooltipText: root.systemFont === "" && root.terminalFont === ""
      ? "Fonts"
      : "System: " + root.systemFont + "\nTerminal: " + root.terminalFont
    onPressed: function(button) { root.togglePanel() }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Process {
    id: hookProc
    command: [root.cli, "install-hook"]
  }

  Process {
    id: systemProc
    command: [root.cli, "system-current"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.systemFont = String(text || "").trim()
    }
  }

  Process {
    id: terminalProc
    command: [root.cli, "terminal-current"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.terminalFont = String(text || "").trim()
    }
  }
}
