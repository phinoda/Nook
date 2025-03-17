import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var windowVisible = true
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
    
    // Create on-screen frame (visible position) - RIGHT SIDE
    onScreenFrame = NSRect(
      x: screenFrame.maxX - windowWidth, // Position at right edge
      y: screenFrame.minY,
      width: windowWidth,
      height: windowHeight
    )
    
    // Create off-screen frame (hidden position, completely off-screen)
    offScreenFrame = NSRect(
      x: screenFrame.maxX + windowWidth + 500, // Move it way off-screen with extra margin
      y: screenFrame.minY,
      width: windowWidth,
      height: windowHeight
    )
    
    // Start with on-screen position
    self.setFrame(onScreenFrame, display: true)
    
    // Configure window appearance for transparency
    self.styleMask.remove(.resizable)
    self.level = NSWindow.Level.floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    
    // Make the window transparent with a white background
    self.isOpaque = true
    self.backgroundColor = NSColor.white
    self.hasShadow = true
    
    // Set the window appearance to light/vibrant light
    self.appearance = NSAppearance(named: .vibrantLight) // Use light appearance instead of dark
    
    // Enable backdrop blur using the window's appearance
    if let contentView = self.contentView {
      // Create a visual effect view that covers the entire window
      let visualEffectView = NSVisualEffectView(frame: contentView.bounds)
      visualEffectView.material = .sheet // This gives a light blur effect
      visualEffectView.blendingMode = .behindWindow // Blur what's behind the window
      visualEffectView.state = .active // Keep the blur active
      visualEffectView.autoresizingMask = [.width, .height]
      
      // Add the visual effect view as the background
      contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
    }
    
    // Register for global mouse move events
    NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
      self?.handleMouseMoved(event)
    }
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
    
    // Initially hide the window after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.hideAppWindow()
    }
    
    print("Setting frames - onScreen: \(onScreenFrame), offScreen: \(offScreenFrame)")
  }
  
  private func handleMouseMoved(_ event: NSEvent) {
    guard let screen = NSScreen.main else { return }
    
    let mouseLocation = NSEvent.mouseLocation
    let screenFrame = screen.visibleFrame
    let rightEdge = screenFrame.maxX
    let distanceFromEdge = rightEdge - mouseLocation.x
    
    // Add debug print to see mouse position (uncomment for debugging)
    // print("Mouse position: \(mouseLocation.x), \(mouseLocation.y), Distance: \(distanceFromEdge)")
    
    // Check if mouse is within threshold from right edge
    if distanceFromEdge <= edgeThreshold {
      if !windowVisible {
        print("Mouse near edge, showing window")
        showAppWindow()
      }
    } else {
      if windowVisible && !self.frame.contains(mouseLocation) {
        print("Mouse away from window, hiding window")
        hideAppWindow()
      }
    }
  }
  
  private func showAppWindow() {
    if !windowVisible {
      // Make window visible but transparent initially
      self.alphaValue = 0.0
      self.makeKeyAndOrderFront(nil)
      
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        // Move window on-screen
        self.animator().setFrame(onScreenFrame, display: true)
        // Make window fully opaque
        self.animator().alphaValue = 1.0
      }
      
      windowVisible = true
      print("Window should now be visible")
    }
  }
  
  private func hideAppWindow() {
    if windowVisible {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        // Move window off-screen
        self.animator().setFrame(offScreenFrame, display: true)
        // Make window completely transparent
        self.animator().alphaValue = 0.0
      }
      
      windowVisible = false
      print("Window should now be hidden")
    }
  }
}

