//
//  WindowController.swift
//  gDraw
//
//  Created by Vincent Liu on 25/9/18.
//  Copyright © 2018 Vincent Liu. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.acceptsMouseMovedEvents = true
        let ViewController = self.window!.contentViewController! as! ViewController
        self.window?.makeFirstResponder(ViewController.ScrollView.documentView!)
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
