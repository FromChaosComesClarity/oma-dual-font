pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// The popup: two pickers, one for the system font and one for the terminal.
//
// Both are searchable because the system list is every family fontconfig
// knows, which runs to a few hundred. The terminal list is monospace only, on
// purpose: putting a proportional family in the terminal is the thing this
// plugin exists to prevent.
//
// The panel holds no font state of its own. It reads the current values off
// the host widget and writes through bin/oma-dual-font, then asks the host to
// re-read. That keeps one source of truth and means the CLI and the popup can
// never disagree.
KeyboardPanel {
  id: root

  property var hostWidget: null
  anchorItem: hostWidget && hostWidget.button ? hostWidget.button : null
  bar: hostWidget ? hostWidget.bar : null
  property var settings: hostWidget ? hostWidget.settings : null
  owner: hostWidget || root

  property bool opened: false
  open: opened
  focusTarget: keyCatcher

  readonly property string cli: hostWidget ? hostWidget.cli : ""
  readonly property string systemFont: hostWidget ? hostWidget.systemFont : ""
  readonly property string terminalFont: hostWidget ? hostWidget.terminalFont : ""

  property var systemOptions: []
  property var terminalOptions: []
  property bool busy: false

  function openPanel() {
    opened = true
    reload()
  }
  function open() { openPanel() }
  function close() { opened = false }
  function toggle() { opened ? close() : openPanel() }

  function reload() {
    if (cli === "") return
    systemListProc.running = true
    terminalListProc.running = true
    if (hostWidget) hostWidget.refresh()
  }

  function splitLines(text) {
    var out = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line !== "") out.push(line)
    }
    return out
  }

  // Changing the system font restarts the shell, which tears this panel down
  // with it. Close first so the popup does not blink out mid-animation.
  function setSystemFont(family) {
    if (family === "" || family === systemFont || busy) return
    busy = true
    systemSetProc.command = [cli, "system-set", family]
    systemSetProc.running = true
    close()
  }

  function setTerminalFont(family) {
    if (family === "" || family === terminalFont || busy) return
    busy = true
    terminalSetProc.command = [cli, "terminal-set", family]
    terminalSetProc.running = true
  }

  contentWidth: fittedContentWidth(Style.space(340))
  contentHeight: fittedContentHeight(column.implicitHeight + Style.space(8))

  // Esc closes the popup. While a dropdown is open it owns the keys instead,
  // so its search field and arrow keys behave; otherwise the catcher would eat
  // every keystroke meant for the filter.
  PanelKeyCatcher {
    id: keyCatcher
    anchors.fill: parent
    blocked: systemDropdown.popupOpen || terminalDropdown.popupOpen
    onCloseRequested: root.close()
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(14)

    Text {
      text: "Fonts"
      color: Color.popups.text
      opacity: 0.6
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    SearchableDropdown {
      id: systemDropdown
      width: parent.width
      label: "System"
      placeholderText: "Search fonts..."
      emptyText: "No font matches"
      fontFamily: Style.font.family
      options: root.systemOptions
      value: root.systemFont
      onChanged: function(family) { root.setSystemFont(family) }
    }

    SearchableDropdown {
      id: terminalDropdown
      width: parent.width
      label: "Terminal"
      placeholderText: "Search monospace fonts..."
      emptyText: "No monospace font matches"
      fontFamily: Style.font.family
      options: root.terminalOptions
      value: root.terminalFont
      onChanged: function(family) { root.setTerminalFont(family) }
    }

    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: "The terminal keeps its own font when the system font changes."
      color: Color.popups.text
      opacity: 0.5
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }

  // Clicking the bar icon is the normal way in. This just makes the popup
  // scriptable the way every other Omarchy panel is, so
  // `omarchy-shell oma-dual-font toggle` reaches it too. It is a plain
  // QtObject, so it hangs off a named property rather than the default
  // contentItem list, which only takes Items.
  property IpcHandler ipc: IpcHandler {
    target: "oma-dual-font"
    function open(): void { root.openPanel() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  property Process systemListProc: Process {
    command: [root.cli, "system-list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.systemOptions = root.splitLines(text)
    }
  }

  property Process terminalListProc: Process {
    command: [root.cli, "terminal-list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.terminalOptions = root.splitLines(text)
    }
  }

  property Process systemSetProc: Process {
    onExited: function(exitCode) {
      root.busy = false
      if (root.hostWidget) root.hostWidget.refresh()
    }
  }

  property Process terminalSetProc: Process {
    onExited: function(exitCode) {
      root.busy = false
      if (root.hostWidget) root.hostWidget.refresh()
    }
  }
}
