import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var fileChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame
    windowFrame.size = NSSize(width: 1200, height: 760)
    self.contentViewController = flutterViewController
    self.title = "DV Max"
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.titlebarSeparatorStyle = .none
    self.styleMask.insert(.fullSizeContentView)
    // The file-drag plugin makes FlutterView.mouseDownCanMoveWindow return
    // YES. With this flag on, AppKit then drags the whole window from any
    // point, and after a move or resize that region covers the cards.
    self.isMovableByWindowBackground = false
    self.backgroundColor = NSColor(srgbRed: 16.0 / 255, green: 20.0 / 255, blue: 24.0 / 255, alpha: 1)
    self.contentMinSize = NSSize(width: 960, height: 640)
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let registrar = flutterViewController.registrar(forPlugin: "DvMaxFileActions")
    let channel = FlutterMethodChannel(
      name: "dvmax.files",
      binaryMessenger: registrar.messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "share":
        guard let path = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        let url = URL(fileURLWithPath: path)
        let picker = NSSharingServicePicker(items: [url])
        let view = flutterViewController.view
        let rect = NSRect(
          x: view.bounds.midX - 2,
          y: view.bounds.midY,
          width: 4,
          height: 4
        )
        picker.show(relativeTo: rect, of: view, preferredEdge: .minY)
        result(nil)
      case "drag":
        if let event = NSApp.currentEvent, self?.isTitleStripEvent(event) == true {
          self?.performDrag(with: event)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    fileChannel = channel

    super.awakeFromNib()
  }

  override func becomeKey() {
    super.becomeKey()
    fileChannel?.invokeMethod("focus", arguments: nil)
  }

  /// The custom title strip is the top 40pt. Only that click may move the window.
  private func isTitleStripEvent(_ event: NSEvent) -> Bool {
    guard let content = contentView else {
      return false
    }
    let point = content.convert(event.locationInWindow, from: nil)
    if content.isFlipped {
      return point.y <= 40
    }
    return point.y >= content.bounds.height - 40
  }
}
