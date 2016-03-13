
import Foundation


public class SuggestionViewController: NSViewController {
    
    
    var suggestionKeyPath: String!

    
    func getSuggestionText() -> String? {
        return self.representedObject?.valueForKeyPath(suggestionKeyPath) as? String
    }
}
