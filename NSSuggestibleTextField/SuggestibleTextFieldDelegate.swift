//
//  SuggestibleTextFieldDelegate.swift
//  NSSuggestibleTextField
//
//  Created by lubos plavucha on 03/04/16.
//  Copyright © 2016 lubos plavucha. All rights reserved.
//

import Foundation

public protocol SuggestibleTextFieldDelegate {
    
    
    func suggestionWindowOpened(_ sender: NSTextField)
    
    
    func suggestionWindowClosed(_ sender: NSTextField)
}
