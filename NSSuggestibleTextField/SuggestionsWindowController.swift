
import Foundation

public class SuggestionsWindowController: NSWindowController {
    
    
    var viewControllers: [NSViewController] = []
    var trackingAreas: [NSTrackingArea] = []
    var parentTextField: NSTextField?
    var localMouseDownEventMonitor: AnyObject?        
    var lostFocusObserver: AnyObject? 
    var action: Selector!
    var target: AnyObject!
    var filterProperty: String!
    var needsLayoutUpdate = false
    var trackerKey = "trackerKey"
    
    
    public init() {
        
        let contentRect = NSRect(x: 0, y: 0, width: 200, height: 200)
        let window = SuggestionsWindow(contentRect: contentRect, styleMask: NSBorderlessWindowMask, backing: .Buffered, `defer`: true)
        super.init(window: window)
        
        let contentView = RoundedCornersView(frame: contentRect)
        window.contentView = contentView
        contentView.autoresizesSubviews = false
        
        self.needsLayoutUpdate = true
    }
    
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    var selectedView: NSView? {
        willSet {
            if let selectedView = self.selectedView as? HighlightingView where selectedView !== newValue {
                selectedView.highlighted = false
            }
        }
        didSet {
            if let selectedView = self.selectedView as? HighlightingView {
                selectedView.highlighted = true
            }
        }
    }
    
    
    func userSetSelectedView(view: NSView?) {
        self.selectedView = view
        NSApp.sendAction(self.action, to: self.target, from: self)
    }
    
    
    func beginForTextField(textField: NSTextField) {
        
        let suggestionWindow = self.window
        let parentWindow = textField.window
        var frame = suggestionWindow!.frame
        frame.size.width = 250  // TODO configurable
        
        // place the suggestion window just underneath the text field
        let textFieldInWindowCoords = textField.convertRect(textField.frame, toView: nil)
        var textFieldInScreen = parentWindow!.convertRectToScreen(textFieldInWindowCoords)
        textFieldInScreen.origin.y -= 2.0
        suggestionWindow!.setFrame(frame, display: false)
        suggestionWindow!.setFrameTopLeftPoint(textFieldInScreen.origin)
        self.layoutSuggestions() // The height of the window will be adjusted in  layoutSuggestions
        
        // add the suggestion window as a child window so that it plays nice with Expose
        parentWindow!.addChildWindow(suggestionWindow!, ordered: .Above)
        
        self.parentTextField = textField
        
        // setup auto cancellation if the user clicks outside the suggestion window and parent text field. Note: this is a local event monitor and will only catch clicks in windows that belong to this application. We use another technique below to catch clicks in other application windows.
        
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEventsMatchingMask([NSEventMask.LeftMouseDownMask, NSEventMask.RightMouseDownMask, NSEventMask.OtherMouseDownMask]) { (var event: NSEvent?) -> NSEvent? in
            
            // If the mouse event is in the suggestion window, then there is nothing to do.
            
            if let window = event?.window where !window.isEqual(suggestionWindow) {
                
                if window.isEqual(parentWindow) {
                    
                    /* Clicks in the parent window should either be in the parent text field or dismiss the suggestions window. We want clicks to occur in the parent text field so that the user can move the caret or select the search text.
                    
                    Use hit testing to determine if the click is in the parent text field. Note: when editing an NSTextField, there is a field editor that covers the text field that is performing the actual editing. Therefore, we need to check for the field editor when doing hit testing.
                    
                    */
                    if let contentView = parentWindow!.contentView {
                        
                        let locationTest = contentView.convertPoint(event!.locationInWindow, fromView:nil)
                        
                        if let hitView = contentView.hitTest(locationTest) {
                            let fieldEditor = self.parentTextField!.currentEditor
                            
                            if !hitView.isEqual(self.parentTextField) && !hitView.isEqual(fieldEditor()) {
                                
                                // Since the click is not in the parent text field, return nil, so the parent window does not try to process it, and cancel the suggestion window.
                                event = nil
                                self.cancelSuggestions()
                            }
                        }
                    }
                } else {
                    
                    // Not in the suggestion window, and not in the parent window. This must be another window or palette for this application.
                    self.cancelSuggestions()
                }
            }
            return event
        }
        
        // We also need to auto cancel when the window loses key status. This may be done via a mouse click in another window, or via the keyboard (cmd-~ or cmd-tab), or a notificaiton. Observing NSWindowDidResignKeyNotification catches all of these cases and the mouse down event monitor catches the other cases.
        lostFocusObserver = NSNotificationCenter.defaultCenter().addObserverForName(NSWindowDidResignKeyNotification, object:parentWindow, queue:nil) { note in
            // lost key status, cancel the suggestion window
            self.cancelSuggestions()
        }
    }
    
    
    func cancelSuggestions() {
        
        let suggestionWindow = self.window
        
        if suggestionWindow!.visible {
            
            // Remove the suggestion window from parent window's child window collection before ordering out or the parent window will get ordered out with the suggestion window.
            suggestionWindow!.parentWindow!.removeChildWindow(suggestionWindow!)
            suggestionWindow?.orderOut(nil)            
        }
        
        // dismantle any observers for auto cancel
        if (lostFocusObserver != nil) {
            NSNotificationCenter.defaultCenter().removeObserver(lostFocusObserver!)
            lostFocusObserver = nil
        }
        if (localMouseDownEventMonitor != nil) {
            NSEvent.removeMonitor(localMouseDownEventMonitor!)
            localMouseDownEventMonitor = nil
        }
    }
    
    
    var suggestions: [AnyObject] = [] {
        didSet {
            if let window = self.window where window.visible {
                self.layoutSuggestions()    // update suggestions (if the window is visible)
            }
        }
    }
    
    
    var selectedSuggestion: AnyObject? {
        get {
            // Find the currently selected view's controller (if there is one) and return the representedObject
            if let selectedViewController = viewControllers.filter({$0.view.isEqual(self.selectedView)}).first as? SuggestionViewController {
                return selectedViewController.representedObject
            }
            return nil
        }
    }
    
    
    func layoutSuggestions() {
        
        if let window = self.window, contentView = window.contentView as? RoundedCornersView {
            
            // Remove any existing suggestion view and associated tracking area and set the selection to nil
            self.selectedView = nil
            
            for viewController in viewControllers {
                viewController.view.removeFromSuperview()
            }
            viewControllers.removeAll()
            
            for trackingArea in trackingAreas {
                contentView.removeTrackingArea(trackingArea)
            }
            trackingAreas.removeAll()
            
            /* Iterate througn each suggestion creating a view for each entry. The width of each suggestion view should match the width of the window. The height is determined by the view's height set in IB.
            */
            
            var contentFrame = contentView.frame
            var frame = NSRect()
            frame.size.height = 0.0
            frame.size.width = NSWidth(contentFrame)
            frame.origin = NSMakePoint(0, contentView.rcvCornerRadius) // offset the Y position so that the suggetion view does not try to draw past the rounded corners.
            
            let bundle = NSBundle(identifier: "com.lubosplavucha.CocoaCleverControls")
            let titleViewController = NSViewController(nibName: "suggestiontitle", bundle: bundle)
            let titleView = titleViewController!.view
            frame.size.height = titleView.frame.size.height
            titleView.frame = frame
            contentView.addSubview(titleViewController!.view)
            
            for suggestion in suggestions {
                frame.origin.y += frame.size.height
                
                let viewController = SuggestionViewController(nibName: "suggestionprototype", bundle: bundle)
                viewController!.suggestionKeyPath = filterProperty
                viewController!.representedObject = suggestion
                let view = viewController!.view as! HighlightingView
                
                // Make the selectedView the samee as the 0th.
                if viewControllers.count == 0 {
                    self.selectedView = view
                }
                
                // Use the height of set in IB of the prototype view as the heigt for the suggestion view.
                frame.size.height = view.frame.size.height
                view.frame = frame
                contentView.addSubview(view)
                
                // don't forget to create the tracking are.
                if let trackingArea = self.getTrackingAreaForView(view) {
                    contentView.addTrackingArea(trackingArea)
                    trackingAreas.append(trackingArea)
                }
                
                viewControllers.append(viewController!)
            }
            
            /* We have added all of the suggestion to the window. Now set the size of the window. */
            
            // Don't forget to account for the extra room needed the rounded corners.
            contentFrame.size.height = NSMaxY(frame) + contentView.rcvCornerRadius
            var winFrame = window.frame
            winFrame.origin.y = NSMaxY(winFrame) - NSHeight(contentFrame)
            winFrame.size.height = NSHeight(contentFrame)
            window.setFrame(winFrame, display: true)
        }     
        
    }
    
    
    func getTrackingAreaForView(view: NSView) -> NSTrackingArea? {
        
        if let trackingRect = self.window?.contentView?.convertRect(view.bounds, fromView: view) {
            
            let trackerData = [trackerKey: view]
            let trackingArea = NSTrackingArea(rect: trackingRect, options: [.MouseEnteredAndExited, .EnabledDuringMouseDrag, .ActiveInActiveApp], owner: self, userInfo: trackerData)
            return trackingArea
        }
        return nil
    }
    
    
    /* The mouse is now over one of our child image views. Update selection and send action.
    
    */
    override public func mouseEntered(event: NSEvent) {
        if let view = event.trackingArea?.userInfo?[trackerKey] as? NSView {
            self.userSetSelectedView(view)
        }        
    }
    
    
    override public func mouseExited(theEvent: NSEvent) {
        self.userSetSelectedView(nil)
    }
    
    
    /* The user released the mouse button. Force the parent text field to send its return action. Notice that there is no mouseDown: implementation. That is because the user may hold the mouse down and drag into another view.
    */
    public override func mouseUp(theEvent: NSEvent) {
        
        if parentTextField != nil {
            parentTextField!.validateEditing()
            parentTextField!.sendAction(parentTextField!.action, to: parentTextField!.target)
        }
        self.cancelSuggestions()
    }
    
    
    override public func moveUp(sender: AnyObject?) {
        
        let selectedView = self.selectedView
        var previousView: NSView? = nil
        
        for viewController in viewControllers {
            let view = viewController.view
            if view.isEqual(selectedView) {
                break
            }
            previousView = view
        }
        if previousView != nil {
            self.userSetSelectedView(previousView!)
        }
    }
    
    
    override public func moveDown(sender: AnyObject?) {
        
        let selectedView = self.selectedView
        var previousView: NSView? = nil
        
        for viewController in viewControllers.reverse() {
            let view = viewController.view
            if view.isEqual(selectedView) {
                break
            }
            previousView = view
        }
        
        if previousView != nil {
            self.userSetSelectedView(previousView!)
        }
    }
}