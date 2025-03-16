import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // Set window width to 350 and height to full screen height
    let windowWidth: CGFloat = 350
    
    // Get the screen size
    guard let screen = NSScreen.main else {
      self.contentViewController = flutterViewController
      RegisterGeneratedPlugins(registry: flutterViewController)
      super.awakeFromNib()
      return
    }
    
    let screenFrame = screen.visibleFrame
    let windowHeight = screenFrame.height // Full screen height
    
    // Create a new frame with the desired size
    let newFrame = NSRect(
      x: screenFrame.maxX - windowWidth, // Position at right edge
      y: screenFrame.minY, // Align with bottom of screen
      width: windowWidth,
      height: windowHeight
    )
    
    self.contentViewController = flutterViewController
    self.setFrame(newFrame, display: true)
    
    // Make the window not resizable to maintain the fixed width
    self.styleMask.remove(.resizable)
    
    // Print screen and window dimensions
    print("Screen size: \(screenFrame.width) x \(screenFrame.height)")
    print("Window size: \(windowWidth) x \(windowHeight)")

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
