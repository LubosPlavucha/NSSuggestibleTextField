
import Foundation
import AppKit

open class SuggestibleTextField: NSTextField, NSTextFieldDelegate {
    
    
    open var entityName: String!     // set from outside (e.g. in Runtime attributes)
    open var filterProperty: String!     // set from outside (e.g. in Runtime attributes)
    open var managedObjectContext: NSManagedObjectContext!   // set from outside
    open var suggestibleTextFieldDelegate: SuggestibleTextFieldDelegate?
    var selectedEntity: AnyObject?  // entity selected in the suggestions list
    var suggestionsController: SuggestionsWindowController?
    var skipNextSuggestion = false
    /** By default set to true. If set to false, the text field will not be autocompleted from the suggestion list. */
    open var autocompletion = true
    /** Moves the focus to the next component after the user presses the Enter key. */
    open var moveToNextViewOnEnter = false

    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isEditable = true
        self.delegate = self
    }
    
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.isEditable = true
        self.delegate = self
    }
    
    
    override open func controlTextDidBeginEditing(_ notification: Notification) {
                
        if suggestionsController == nil {
            suggestionsController = SuggestionsWindowController()
            suggestionsController!.target = self
            suggestionsController!.action = #selector(SuggestibleTextField.updateWithSelectedSuggestion(_:))
            suggestionsController!.filterProperty = filterProperty
            suggestionsController?.suggestibleTextFieldDelegate = self.suggestibleTextFieldDelegate
        }
        self.updateSuggestionsFromControl(notification.object as AnyObject?)
    }
    
    
    override open func controlTextDidChange(_ notification: Notification) {
        
        if !self.skipNextSuggestion {
            self.updateSuggestionsFromControl(notification.object as AnyObject?)
        } else {
            // If we are skipping this suggestion, the set the selected entity to nil and cancel the suggestions window.
            self.selectedEntity = nil
            suggestionsController!.cancelSuggestions()
            
            // This suggestion has been skipped, don't skip the next one.
            self.skipNextSuggestion = false
        }
    }

    
    override open func controlTextDidEndEditing(_ notification: Notification) {
        suggestionsController?.cancelSuggestions()
    }

    
    /* This is the action method for when the user changes the suggestion selection. Note, this action is called continuously as the suggestion selection changes while being tracked and does not denote user committal of the suggestion.
    */
    func updateWithSelectedSuggestion(_ sender: AnyObject) {
        
        if let suggestionsWindowController = sender as? SuggestionsWindowController, let selectedSuggestion = suggestionsWindowController.selectedSuggestion {
            
            if let fieldEditor = self.window?.fieldEditor(false, for: self) {
                
                self.updateFieldEditor(fieldEditor, suggestion: selectedSuggestion)
                self.selectedEntity = selectedSuggestion
            }
        }
    }
    
    
    func updateSuggestionsFromControl(_ control: AnyObject?) {
        
        if let fieldEditor = self.window?.fieldEditor(false, for: control) {
            
            // Only use the text up to the caret position
            let selection = fieldEditor.selectedRange
            if let text = fieldEditor.string?.substring(to: fieldEditor.string!.characters.index(fieldEditor.string!.startIndex, offsetBy: selection.location)) {
                
                let suggestions = self.getSuggestionsForText(text)
                
                if suggestions.count > 0 {
                    
                    // We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
                    let suggestion = suggestions[0]
                    self.selectedEntity = suggestion
                    
                    // update the field editor
                    if autocompletion {
                        self.updateFieldEditor(fieldEditor, suggestion: suggestion)
                    }
                    suggestionsController?.suggestions = suggestions
                        
                    if let window = suggestionsController?.window , !window.isVisible {
                        suggestionsController!.beginForTextField(control as! NSTextField)
                        suggestibleTextFieldDelegate?.suggestionWindowOpened(self)
                    }
                    
                } else {
                    // No suggestions. Cancel the suggestion window.
                    self.selectedEntity = nil
                    suggestionsController?.cancelSuggestions()
                }
            } else {
                suggestionsController?.cancelSuggestions()
            }
        }
    }
    
    
    func updateFieldEditor(_ fieldEditor: NSText, suggestion: AnyObject) {
        
        if let suggestionString = suggestion.value(forKeyPath: filterProperty) as? String {
            let selection = NSMakeRange(fieldEditor.selectedRange.location, suggestionString.characters.count)
            fieldEditor.string = suggestionString
            fieldEditor.selectedRange = selection
        }
    }
    
    
    // Can be overriden.
    open func getSuggestionsForText(_ text: String) -> [AnyObject] {
                
        let beginsWithPredicate = NSPredicate(format: filterProperty + " BEGINSWITH[cd] %@", text)
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = beginsWithPredicate
        let sorter = NSSortDescriptor(key: filterProperty , ascending: true)
        request.sortDescriptors = [sorter]
        
        var error: NSError? = nil
        var fetchedResult: [AnyObject]?
        do {
            fetchedResult = try managedObjectContext.fetch(request)
        } catch let error1 as NSError {
            error = error1
            fetchedResult = nil
        }
        if error != nil {
            NSLog("errore: \(error)")
        }
                
        return fetchedResult != nil ? fetchedResult! : []
    }
    
    
    open func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        
        // Enter key pressed
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            
            var result =  false // by default must return false not to block the Enter key event handling if the suggestible text field hasn't opened the suggestions window
            
            if let fieldEditor = self.window?.fieldEditor(false, for: self) , suggestionsController?.window?.isVisible == true {
                    
                // the suggestion window is displayed
                
                if self.selectedEntity != nil && !autocompletion {
                    // if the text field is not autocompleted -> set the text value from the suggestions list if the user selected an entry and pressed the Enter
                    self.updateFieldEditor(fieldEditor, suggestion: self.selectedEntity!)
                }
                suggestionsController?.cancelSuggestions()
                result = true // return true because we want to handle the Enter key event completely here; it should not be handled by the system somewhere else in the case the suggestions window is opened
            }
            if let nextView = self.nextKeyView , moveToNextViewOnEnter {
                self.window?.makeFirstResponder(nextView)
            }
            return result    
        
        } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
            // Move up in the suggested selections list
            suggestionsController?.moveUp(textView)
            return true
        } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
            // Move up in the suggested selections list
            suggestionsController?.moveDown(textView)
            return true
        } else if commandSelector == #selector(NSResponder.deleteForward(_:)) || commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            /* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
            
            */
            self.skipNextSuggestion = true
            return false
        } else if commandSelector == #selector(NSResponder.complete(_:)) {
            // The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
            
            if suggestionsController?.window?.isVisible == true {
                suggestionsController?.cancelSuggestions()
            } else {
                self.updateSuggestionsFromControl(control)
            }
            return true
        }

        // This is a command that we don't specifically handle, let the field editor do the appropriate thing.
        return false
    }
}
