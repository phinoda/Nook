import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var windowVisible = true // Start as visible
  private let edgeThreshold: CGFloat = 20
  private var onScreenFrame: NSRect = .zero
  private var offScreenFrame: NSRect = .zero
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    
    // Set window width to 350 and height to full screen height
    let windowWidth: CGFloat = 350
    
    // Get the screen size
    guard let screen = NSScreen.main else {
      RegisterGeneratedPlugins(registry: flutterViewController)
      super.awakeFromNib()
      return
    }
    
    let screenFrame = screen.visibleFrame
    let windowHeight = screenFrame.height
    
    // Create on-screen frame (visible position)
    onScreenFrame = NSRect(
      x: screenFrame.maxX - windowWidth,
      y: screenFrame.minY,
      width: windowWidth,
      height: windowHeight
    )
    
    // Create off-screen frame (hidden position, just off the right edge)
    offScreenFrame = NSRect(
      x: screenFrame.maxX + 5, // Just off-screen
      y: screenFrame.minY,
      width: windowWidth,
      height: windowHeight
    )
    
    // Start with on-screen position
    self.setFrame(onScreenFrame, display: true)
    
    // Configure window appearance
    self.styleMask.remove(.resizable)
    self.level = NSWindow.Level.floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    
    // Register for global mouse move events
    NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
      self?.handleMouseMoved(event)
    }
    
    print("Window initialized. Screen width: \(screenFrame.width), threshold: \(edgeThreshold)")
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
    
    // Initially hide the window after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.hideAppWindow()
    }
  }
  
  private func handleMouseMoved(_ event: NSEvent) {
    guard let screen = NSScreen.main else { return }
    
    let mouseLocation = NSEvent.mouseLocation
    let screenFrame = screen.visibleFrame
    let rightEdge = screenFrame.maxX
    let distanceFromEdge = rightEdge - mouseLocation.x
    
    
    // Check if mouse is within threshold from right edge
    if distanceFromEdge <= edgeThreshold {
      if !windowVisible {
        print("Showing window - mouse is near edge")
        showAppWindow()
      }
    } else {
      if windowVisible && !self.frame.contains(mouseLocation) {
        print("Hiding window - mouse moved away")
        hideAppWindow()
      }
    }
  }
  
  private func showAppWindow() {
    if !windowVisible {
      print("Making window visible")
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        self.animator().setFrame(onScreenFrame, display: true)
        self.animator().alphaValue = 1.0
      }
      self.makeKeyAndOrderFront(nil)
      windowVisible = true
    }
  }
  
  private func hideAppWindow() {
    if windowVisible {
      print("Making window invisible")
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        self.animator().setFrame(offScreenFrame, display: true)
        self.animator().alphaValue = 0.5 // Not fully transparent
      }
      windowVisible = false
    }
  }
}
