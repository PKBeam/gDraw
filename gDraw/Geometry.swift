//
//  helper.swift
//  gDraw
//
//  Created by Vincent Liu on 25/9/18.
//  Copyright © 2018 Vincent Liu. All rights reserved.
//

import Cocoa

// extend + and - to NSPoint
extension NSPoint {
    static func +(left: NSPoint, right: NSPoint) -> NSPoint {
        return NSPoint(x: left.x + right.x, y: left.y + right.y)
    }
    static func -(left: NSPoint, right: NSPoint) -> NSPoint {
        return NSPoint(x: left.x - right.x, y: left.y - right.y)
    }
}

extension NSPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }
}

class Line: NSBezierPath {

    static func == (lhs: Line, rhs: Line) -> Bool {
        return (lhs.endpoints.0 == rhs.endpoints.0 && lhs.endpoints.1 == rhs.endpoints.1) || (lhs.endpoints.0 == rhs.endpoints.1 && lhs.endpoints.1 == rhs.endpoints.0)
    }

    /**
    The origin (one of the endpoints) of the line.
    */
    var origin: NSPoint
    
    /**
    The endpoints of the line.
    */
    var endpoints: (NSPoint, NSPoint) { return (origin, currentPoint) }
    
    /**
    Creates a line using two points.
    - Parameter origin: The start of the line.
    - Parameter endpoint: The end of the line. If nil, this is set to the origin.
    */
    init(_ origin: NSPoint, _ endpoint: NSPoint?) {
        self.origin = origin
        super.init()
        self.move(to: origin)
        if let e = endpoint {
            self.line(to: e)
        }
    }
    
    // angle should be in degrees
    /*
            • P
           /|
        r / | y     y = r sin θ
         /θ |       x = r cos θ
      O •---+
          x
                    */
    
    /**
    Creates a line using an origin, distance and angle (in radians).
    - Parameter origin: The start of the line.
    - Parameter distance: The length of the line (must be non-negative).
    - Parameter rad: The angle, in radians, between the origin and endpoint of the line.
    */
    
    init(origin: NSPoint, distance: CGFloat, rad: CGFloat) {
        self.origin = origin
        super.init()
        self.move(to: origin)
        let endpointX = origin.x + distance * cos(rad)
        let endpointY = origin.y + distance * sin(rad)
        self.line(to: Point(endpointX, endpointY))
    }
    
    /**
    Creates a line using an origin, distance and angle (in degrees).
    - Parameter origin: The start of the line.
    - Parameter distance: The length of the line (must be non-negative).
    - Parameter deg: The angle, in degrees, between the origin and endpoint of the line.
    */
    
    convenience init(origin: NSPoint, distance: CGFloat, deg: CGFloat) {
        let degInRad = deg * CGFloat(Double.pi/180.0)
        self.init(origin: origin, distance: distance, rad: degInRad)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.origin = Point(0, 0)
        super.init(coder: aDecoder)
    }
}

func Point(_ x: Int, _ y: Int) -> NSPoint {
    return NSPoint(x: x, y: y)
}

func Point(_ x: Double, _ y: Double) -> NSPoint {
    return NSPoint(x: x, y: y)
}

func Point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
    return NSPoint(x: x, y: y)
}

func intersection(_ l1: Line, _ l2: Line) -> NSPoint? {
    /*
        Let t, t' be in [0,1], then

        l1: (a,b) to (c,d)
        l1(t) = (t(c-a)+a, t(d-b)+b)

        l2: (e,f) to (g,h)
        l2(t') = (t'(g-e)+e, t'(h-f)+f)

        are two line segments whose intersection is

        t = ((f-h)a+(g-e)b+eh-fg) / ((f-h)(a-c)+(g-e)(b-d))

        if t is in [0, 1].
     */

    let a = l1.endpoints.0.x
    let b = l1.endpoints.0.y
    let c = l1.endpoints.1.x
    let d = l1.endpoints.1.y
    let e = l2.endpoints.0.x
    let f = l2.endpoints.0.y
    let g = l2.endpoints.1.x
    let h = l2.endpoints.1.y

    let tn = (f - h)*a + (g - e)*b + e*h - f*g
    let td = (f - h)*(a - c) + (g - e)*(b - d)
    let t1: CGFloat = tn/td
    let t2: CGFloat = (t1 * (b - d) + (f - b))/(f - h)

    // intersection is inside the lines
    // (need to check t values for BOTH lines)
    let delta: CGFloat = 10e-12
    if (0 <= t1 + delta && t1 - delta <= 1) && (0 <= t2 + delta && t2 - delta <= 1) {
        return NSPoint(x: t1*(c - a) + a, y: t1*(d - b) + b)
    // intersection is outside the lines
    } else {
//        print("t: (\(t1),\(t2))")
        return nil
    }
}

/**
    Returns the square of the L-2 norm (length) of a point.
 */
func norm2_sq(_ p1: NSPoint) -> CGFloat {
    return pow(p1.x, 2) + pow(p1.y, 2)
}

/**
   Returns the L-infinity norm (length) of a point.
*/
func normInf(_ p1: NSPoint) -> CGFloat {
    return max(abs(p1.x), abs(p1.y));
}

func isWithin(_ p1: NSPoint, _ p2: NSPoint, radius: CGFloat) -> Bool {
    // check L-inf norm first because it's faster
    // since it quickly eliminates points that are far away
    if normInf(p1 - p2) <= radius {
        // square both sides; sqrt is slower
        return norm2_sq(p1 - p2) <= pow(radius, 2)
    } else {
        return false
    }
}
