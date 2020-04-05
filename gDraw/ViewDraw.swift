//
//  ViewDraw.swift
//  gDraw
//
//  Created by Vincent Liu on 24/9/18.
//  Copyright © 2018 Vincent Liu. All rights reserved.
//

import Cocoa

class ViewDraw: NSView {
    
    override var acceptsFirstResponder: Bool { return true }

    // width of lines drawn
    let lineWidth: CGFloat = 2.0
    var pointRadius: CGFloat {
        return 3.0
    }
    var pointCircleLineWidth: CGFloat {
        return 0
    }
    var snapRadius: CGFloat {
        return 10.0/internalZoom
    }
    var snapCircleLineWidth: CGFloat {
        return 1.5/internalZoom
    }

    // track the currently snapped point
    var currentlySnappedPoint: NSPoint?
    var drawRectOfSnappedPoint: NSRect? {
        if let p = currentlySnappedPoint {
            return getDrawRect(p, radius: snapRadius, stroke: snapCircleLineWidth)
        }
        return nil
    }
    var snapPointNeedsUpdate: Bool {
        // no snapped point, or mouse moved out of range of snapped point
        return currentlySnappedPoint == nil || !isWithin(mouseLocation, currentlySnappedPoint!, radius: snapRadius)
    }
    
    // list of all lines, curves etc.
    var drawObjects: [Line] = []

    // the line currently being drawn, if any.
    var lineBeingDrawn: Line?
    var isDrawing: Bool {
        return lineBeingDrawn != nil
    }

    // list of all intersections in drawObjects
    // [Line] must have at least two members
    var intersections: [NSPoint: [Line]] = [:]
    
    // user-readable zoom percentage
    var magnification: Int {
        return Int(internalZoom * 100)
    }
    // zoom multiplier
    var internalZoom: CGFloat = 1
    
    // returns mouse location in the co-ordinates of the inside document view
    var mouseLocation: NSPoint {
    
        let mouseInWindow = self.window!.mouseLocationOutsideOfEventStream
        
        /*
            calculate location of the mouse across the window as %
            account for toolbar + title bar height
            toolbar + title bar: 80
            bottom bar: 40
                                                                    */
        let percentMouseX = mouseInWindow.x / self.window!.frame.width
        let percentMouseY = (mouseInWindow.y - 40) / (self.window!.frame.height - 120)
        
        // apply the percentages to the inside document view
        let translatedX = visibleRect.minX + (visibleRect.maxX - visibleRect.minX) * percentMouseX
        let translatedY = visibleRect.minY + (visibleRect.maxY - visibleRect.minY) * percentMouseY
        
        return Point(translatedX, translatedY)
    }

    func getDrawRect(_ p: NSPoint, radius r: CGFloat, stroke s: CGFloat) -> NSRect {
         return NSRect(
            origin: Point(p.x - (r + s), p.y - (r + s)),
            size: CGSize(width: 2*(r + s), height: 2*(r + s))
        )
    }
    func getDrawRect(_ l: Line, stroke s: CGFloat) -> NSRect {
        return l.bounds.insetBy(dx: -s, dy: -s)
    }
    /**
    Checks if any line endpoints are near the mouse location.
    - parameter exclusions: An array of points to exclude from the check.
    */
    func findSnappedPoint(excluding exclusions: [NSPoint]) -> NSPoint? {
        var snappedPoint: NSPoint?

        // get list of all points
        var pointList: [NSPoint] = []
        for i in drawObjects {
            pointList.append(i.endpoints.0)
            pointList.append(i.endpoints.1)
        }

        // search the list
        for point in pointList {
            if exclusions.contains(point) {
                continue
            }

            if isWithin(mouseLocation, point, radius: snapRadius) {
                snappedPoint = point
            }
        }
        return snappedPoint
    }
    /**
    Checks if any line endpoints are near the mouse location.
    */
    func findSnappedPoint() -> NSPoint? {
        return findSnappedPoint(excluding: [])
    }

    func startDrawing() {
        lineBeingDrawn = Line(findSnappedPoint(excluding: []) ?? mouseLocation, nil)
    }

    func updateDrawing() {
        // calculate what to redraw
        let prevBounds = getDrawRect(lineBeingDrawn!, stroke: lineWidth)
        lineBeingDrawn = Line(lineBeingDrawn!.origin, currentlySnappedPoint ?? mouseLocation)
        let newBounds = getDrawRect(lineBeingDrawn!, stroke: lineWidth)
        let boundsToRedraw = prevBounds.union(newBounds)
        self.setNeedsDisplay(boundsToRedraw)
    }

    // TODO: intersections on finished lines arent showing up?
    func finishDrawing() {
        let line = lineBeingDrawn!
        // firstly...
        // check if the line is a duplicate (i.e. in the array of existing lines)
        if drawObjects.contains(line) {
            self.setNeedsDisplay(line.bounds.insetBy(dx: -lineWidth, dy: -lineWidth))
        } else {
            drawObjects.append(line)
        }

        // check for, and add intersections
        let checklist = drawObjects
//        print("DRAW: (\(line.endpoints.0.x),\(line.endpoints.0.y)), (\(line.endpoints.1.x),\(line.endpoints.1.y))")
        for eachLine in checklist {
            if eachLine == line {
                continue
            }
//            print("line: (\(eachLine.endpoints.0.x),\(eachLine.endpoints.0.y)), (\(eachLine.endpoints.1.x),\(eachLine.endpoints.1.y))")
            if let p = intersection(line, eachLine) {
//                print("INTERSECTION at (\(p.x),\(p.y))")
                // add line to intersections list
                if var arr = intersections[p] {
                    arr.append(line)
                } else {
                    intersections[p] = [line, eachLine]
                }
                // mark intersect pt as needing redraw
                self.setNeedsDisplay(getDrawRect(p, radius: pointRadius, stroke: pointCircleLineWidth))
            }
        }

        // finally...
        lineBeingDrawn = nil
    }

    func undo() {
        if drawObjects.isEmpty {
            return
        }

        let removed = drawObjects.removeLast()
        self.setNeedsDisplay(getDrawRect(removed, stroke: lineWidth))
        for (point, array) in intersections {
            // intersection with only one other line
            if array.count == 2 && array.contains(removed) {
                intersections.removeValue(forKey: point)
                self.setNeedsDisplay(getDrawRect(point, radius: pointRadius, stroke: pointCircleLineWidth))
            }
        }
    }

    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        
        let area = visibleRect.size.height * visibleRect.size.width
        let totalArea = bounds.height * bounds.width
        
        internalZoom = sqrt(totalArea/area)
        
        NotificationCenter.default.post(name: NSNotification.Name("didMagnify"), object: nil)
    }
    
    override func mouseDown(with event: NSEvent) {
        if isDrawing {
            finishDrawing()
        } else {
            startDrawing()
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        if isDrawing {
            updateDrawing()
        }
        if snapPointNeedsUpdate {

            let oldRect = drawRectOfSnappedPoint ?? NSRect()

            // update snapped point
            currentlySnappedPoint = findSnappedPoint()

            // handle redrawing of snapped point
            let newRect = drawRectOfSnappedPoint ?? NSRect()
            let dirtyRect = oldRect.union(newRect)
            if !NSIsEmptyRect(dirtyRect) {
                self.setNeedsDisplay(dirtyRect)
            }
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        var stroke = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        stroke.setStroke()

        // draw lines
        for i in drawObjects {
            i.lineWidth = lineWidth
            i.stroke()
        }

        if let line = lineBeingDrawn {
            line.lineWidth = lineWidth
            line.stroke()
        }

        // draw red circle around snapped point
        if let p = currentlySnappedPoint {
            // "origin" is the bottom-left corner of the circle rect region
            let circleOrigin = p - Point(snapRadius, snapRadius)
            let circleSize = CGSize(width: (2*snapRadius), height: (2*snapRadius))
            let circleRectRegion = NSRect(origin: circleOrigin, size: circleSize)
            let snapHighlight = NSBezierPath(ovalIn: circleRectRegion)

            stroke = NSColor(red: 1, green: 0, blue: 0, alpha: 0.5)
            stroke.setStroke()

            snapHighlight.lineWidth = snapCircleLineWidth
            snapHighlight.stroke()
        }

        // draw intersections
        for (p, _) in intersections {
            // "origin" is the bottom-left corner of the circle rect region
            let circleOrigin = p - Point(pointRadius, pointRadius)
            let circleSize = CGSize(width: (2*pointRadius), height: (2*pointRadius))
            let circleRectRegion = NSRect(origin: circleOrigin, size: circleSize)
            let snapHighlight = NSBezierPath(ovalIn: circleRectRegion)

            stroke = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
            stroke.setFill()

            snapHighlight.lineWidth = pointCircleLineWidth
            snapHighlight.fill()
        }
    }
}
