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
    
    // Create off-screen frame (hidden position, just off the right edge)
    offScreenFrame = NSRect(
      x: screenFrame.maxX + 5, // Just off-screen to the right
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
    
    // Make the window transparent
    self.isOpaque = false
    self.backgroundColor = NSColor.clear
    self.hasShadow = false
    self.alphaValue = 0.75 // 25% transparent
    
    // Create a visual effect view for background blur
    if let contentView = self.contentView {
      // Make sure the content view can have layers
      contentView.wantsLayer = true
      
      // Create a visual effect view with the same size as the content view
      let visualEffectView = NSVisualEffectView(frame: contentView.bounds)
      
      // Configure the visual effect for maximum blur
      visualEffectView.material = .hudWindow // This gives a strong blur effect
      visualEffectView.blendingMode = .behindWindow // Blur what's behind the window
      visualEffectView.state = .active // Keep the blur active
      
      // Make sure the visual effect view resizes with the window
      visualEffectView.autoresizingMask = [.width, .height]
      
      // Add the visual effect view behind all other content
      contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
      
      // For even more blur, you can add a second visual effect view with different settings
      let secondaryBlurView = NSVisualEffectView(frame: contentView.bounds)
      secondaryBlurView.material = .sheet
      secondaryBlurView.blendingMode = .withinWindow
      secondaryBlurView.state = .active
      secondaryBlurView.autoresizingMask = [.width, .height]
      visualEffectView.addSubview(secondaryBlurView)
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
        showAppWindow()
      }
    } else {
      if windowVisible && !self.frame.contains(mouseLocation) {
        hideAppWindow()
      }
    }
  }
  
  private func showAppWindow() {
    if !windowVisible {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        self.animator().setFrame(onScreenFrame, display: true)
        self.animator().alphaValue = 0.75 // 25% transparent when visible
      }
      self.makeKeyAndOrderFront(nil)
      windowVisible = true
    }
  }
  
  private func hideAppWindow() {
    if windowVisible {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.2
        self.animator().setFrame(offScreenFrame, display: true)
        self.animator().alphaValue = 0.5
      }
      windowVisible = false
    }
  }
}

