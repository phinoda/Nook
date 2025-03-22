import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var windowVisible = true
  private var windowPeeking = false
  private let edgeThreshold: CGFloat = 20
  private var onScreenFrame: NSRect = .zero
  private var offScreenFrame: NSRect = .zero
  private var peekScreenFrame: NSRect = .zero
  private var peekWidth: CGFloat = 40 // Width of the window portion to show when peeking
  
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
    
    // Create peek-screen frame (partially visible position)
    peekScreenFrame = NSRect(
      x: screenFrame.maxX - peekWidth, // Show only peekWidth pixels
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
    
    // Register for local mouse down events
    NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
      self?.handleMouseDown(event)
      return event
    }
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
    
    // Initially hide the window after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.hideAppWindow()
    }
    
    print("Setting frames - onScreen: \(onScreenFrame), peekScreen: \(peekScreenFrame), offScreen: \(offScreenFrame)")
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
      if !windowVisible && !windowPeeking {
        peekAppWindow()
      }
    } else {
      if windowVisible && !self.frame.contains(mouseLocation) {
        hideAppWindow()
      } else if windowPeeking && !self.frame.contains(mouseLocation) {
        hideAppWindow()
      }
    }
  }
  
  private func handleMouseDown(_ event: NSEvent) {
    if windowPeeking {
      // If the window is in peek state and clicked, show it fully
      showAppWindow()
      return
    }
  }
  
  private func showAppWindow() {
    windowPeeking = false
    
    if !windowVisible {
      // Make window visible
      self.makeKeyAndOrderFront(nil)
      
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        // Move window on-screen
        self.animator().setFrame(onScreenFrame, display: true)
        // Make window fully opaque
        self.animator().alphaValue = 1.0
      }
      
      windowVisible = true
      print("Window should now be fully visible")
    }
  }
  
  private func peekAppWindow() {
    // Show just a portion of the window
    self.makeKeyAndOrderFront(nil)
    
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.2
      // Move window to peek position
      self.animator().setFrame(peekScreenFrame, display: true)
      // Make window fully opaque
      self.animator().alphaValue = 1.0
    }
    
    windowPeeking = true
    windowVisible = false
    print("Window should now be peeking")
  }
  
  private func hideAppWindow() {
    if windowVisible || windowPeeking {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        // Move window off-screen
        self.animator().setFrame(offScreenFrame, display: true)
        // Make window completely transparent
        self.animator().alphaValue = 0.0
      }
      
      windowVisible = false
      windowPeeking = false
      print("Window should now be hidden")
    }
  }
}

