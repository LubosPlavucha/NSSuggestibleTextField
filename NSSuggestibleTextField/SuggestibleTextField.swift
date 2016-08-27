
import Foundation
import AppKit

public class SuggestibleTextField: NSTextField, NSTextFieldDelegate {
    
    
    public var entityName: String!     // set from outside (e.g. in Runtime attributes)
    public var filterProperty: String!     // set from outside (e.g. in Runtime attributes)
    public var managedObjectContext: NSManagedObjectContext!   // set from outside
    public var suggestibleTextFieldDelegate: SuggestibleTextFieldDelegate?
    var selectedEntity: AnyObject?  // entity selected in the suggestions list
    var suggestionsController: SuggestionsWindowController?
    var skipNextSuggestion = false
    public var updateFieldEditor = true

    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.editable = true
        self.delegate = self
    }
    
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.editable = true
        self.delegate = self
    }
    
    
    override public func controlTextDidBeginEditing(notification: NSNotification) {
                
        if suggestionsController == nil {
            suggestionsController = SuggestionsWindowController()
            suggestionsController!.target = self
            suggestionsController!.action = #selector(SuggestibleTextField.updateWithSelectedSuggestion(_:))
            suggestionsController!.filterProperty = filterProperty
        }
        self.updateSuggestionsFromControl(notification.object)
    }
    
    
    override public func controlTextDidChange(notification: NSNotification) {
        
        if !self.skipNextSuggestion {
            self.updateSuggestionsFromControl(notification.object)
        } else {
            // If we are skipping this suggestion, the set the selected entity to nil and cancel the suggestions window.
            self.selectedEntity = nil
            suggestionsController!.cancelSuggestions()
            
            // This suggestion has been skipped, don't skip the next one.
            self.skipNextSuggestion = false
        }
    }

    
    override public func controlTextDidEndEditing(notification: NSNotification) {
        suggestionsController?.cancelSuggestions()
    }

    
    /* This is the action method for when the user changes the suggestion selection. Note, this action is called continuously as the suggestion selection changes while being tracked and does not denote user committal of the suggestion.
    */
    func updateWithSelectedSuggestion(sender: AnyObject) {
        
        if let suggestionsWindowController = sender as? SuggestionsWindowController, selectedSuggestion = suggestionsWindowController.selectedSuggestion {
            
            if let fieldEditor = self.window?.fieldEditor(false, forObject: self) {
                
                self.updateFieldEditor(fieldEditor, suggestion: selectedSuggestion)
                self.selectedEntity = selectedSuggestion
            }
        }
    }
    
    
    func updateSuggestionsFromControl(control: AnyObject?) {
        
        if let fieldEditor = self.window?.fieldEditor(false, forObject: control) {
            
            // Only use the text up to the caret position
            let selection = fieldEditor.selectedRange
            if let text = fieldEditor.string?.substringToIndex(fieldEditor.string!.startIndex.advancedBy(selection.location)) {
                
                let suggestions = self.getSuggestionsForText(text)
                
                if suggestions.count > 0 {
                    
                    // We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
                    let suggestion = suggestions[0]
                    self.selectedEntity = suggestion
                    
                    // update the field editor - normally this should be the case
                    if updateFieldEditor {
                        self.updateFieldEditor(fieldEditor, suggestion: suggestion)
                    }
                    suggestionsController?.suggestions = suggestions
                        
                    if let window = suggestionsController?.window where !window.visible {
                        suggestionsController!.beginForTextField(control as! NSTextField)
                        suggestibleTextFieldDelegate?.suggestionWindowOpened(self)
                    }
                    
                } else {
                    // No suggestions. Cancel the suggestion window.
                    self.selectedEntity = nil
                    suggestionsController?.cancelSuggestions()
                    suggestibleTextFieldDelegate?.suggestionWindowClosed(self)
                }
            } else {
                suggestionsController?.cancelSuggestions()
            }
        }
    }
    
    
    func updateFieldEditor(fieldEditor: NSText, suggestion: AnyObject) {
        
        if let suggestionString = suggestion.valueForKeyPath(filterProperty) as? String {
            let selection = NSMakeRange(fieldEditor.selectedRange.location, suggestionString.characters.count)
            fieldEditor.string = suggestionString
            fieldEditor.selectedRange = selection
        }
    }
    
    
    // Can be overriden.
    public func getSuggestionsForText(text: String) -> [AnyObject] {
                
        let beginsWithPredicate = NSPredicate(format: filterProperty + " BEGINSWITH[cd] %@", text)
        
        let request = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = beginsWithPredicate
        let sorter = NSSortDescriptor(key: filterProperty , ascending: true)
        request.sortDescriptors = [sorter]
        
        var error: NSError? = nil
        var fetchedResult: [AnyObject]?
        do {
            fetchedResult = try managedObjectContext.executeFetchRequest(request)
        } catch let error1 as NSError {
            error = error1
            fetchedResult = nil
        }
        if error != nil {
            NSLog("errore: \(error)")
        }
                
        return fetchedResult != nil ? fetchedResult! : []
    }
    
    
    public func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        
        // if the field editor is not updated automatically, do it after the Enter is pressed
        if !updateFieldEditor && commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Enter pressed - update text field with the selected value in the suggestion list
            if let fieldEditor = self.window?.fieldEditor(false, forObject: self) where self.selectedEntity != nil {
                self.updateFieldEditor(fieldEditor, suggestion: self.selectedEntity!)
                suggestionsController?.cancelSuggestions()
            }
            return false
        }
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            // Move up in the suggested selections list
            suggestionsController?.moveUp(textView)
            return true
        }
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            // Move up in the suggested selections list
            suggestionsController?.moveDown(textView)
            return true
        }
        if commandSelector == #selector(NSResponder.deleteForward(_:)) || commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            /* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
            
            */
            self.skipNextSuggestion = true
            return false
        }
        if commandSelector == #selector(NSResponder.complete(_:)) {
            // The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
            
            if suggestionsController?.window?.visible == true {
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
