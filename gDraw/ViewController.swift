//
//  ViewController.swift
//  gDraw
//
//  Created by Vincent Liu on 24/9/18.
//  Copyright © 2018 Vincent Liu. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var ScrollView: NSScrollView!
    
    @IBOutlet weak var lblZoom: NSTextField!

    // TODO: implement this with UndoManager
    @IBAction func btnUndo(_ sender: Any) {
        let viewDraw = ScrollView.documentView as! ViewDraw
        viewDraw.undo()
    }
    
    @IBAction func btnResetZoom(_ sender: Any) {
        let viewDraw = ScrollView.documentView as! ViewDraw
        viewDraw.internalZoom = 100
        ScrollView.magnification = 1.0
        self.lblZoom.stringValue = "Zoom: 100%"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.view.window?.acceptsMouseMovedEvents = true
        
        NotificationCenter.default.addObserver(forName: NSScrollView.didEndLiveMagnifyNotification, object: nil, queue: nil, using: { _ in
            if self.ScrollView.magnification == 1 {
                self.ScrollView.hasVerticalScroller = false
                self.ScrollView.hasHorizontalScroller = false
            } else {
                self.ScrollView.hasVerticalScroller = true
                self.ScrollView.hasHorizontalScroller = true
            }
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("didMagnify"), object: nil, queue: nil, using: { _ in
            let viewDraw = self.ScrollView.documentView as! ViewDraw
            self.lblZoom.stringValue = "Zoom: \(viewDraw.magnification)%"
        })
        
        ScrollView.magnification = 1.0
        ScrollView.allowsMagnification = true
        ScrollView.minMagnification = 1.0
        ScrollView.hasVerticalScroller = false
        ScrollView.hasHorizontalScroller = false
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

