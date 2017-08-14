//
//  SwipeKit.swift
//  SwipeKit
//
//  Created by Cem Olcay on 14/08/2017.
//  Copyright © 2017 cemolcay. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

infix operator &/

extension CGFloat {
  /// Utility function to avoid NaN results when divide something with zero.
  ///
  /// - Parameters:
  ///   - lhs: Value going to be divide.
  ///   - rhs: Divider value.
  /// - Returns: Returns zero if divider is zero. Else returns the division.
  public static func &/(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
    if rhs == 0 {
      return 0
    }
    return lhs/rhs
  }
}

/// y = mx + b.
public struct Slope {

  /// Slope of the equation.
  public var m: CGFloat

  /// Constant of the equation.
  public var b: CGFloat

  /// Initilize the slope with given two points.
  ///
  /// - Parameters:
  ///   - p1: First point.
  ///   - p2: Second point.
  public init(p1: CGPoint, p2: CGPoint) {
    m = (p2.y - p1.y) &/ (p2.x - p1.x)
    b = p1.y - (m * p1.x)
  }

  /// Initilize with slope and constant.
  ///
  /// - Parameters:
  ///   - m: Slope.
  ///   - b: Constant.
  public init(m: CGFloat, b: CGFloat) {
    self.m = m
    self.b = b
  }

  /// Calcualtes the distance between a point and itself by determining perpendecular length from point.
  ///
  /// - Parameter point: Distance of point we want to calculate.
  /// - Returns: Returns the perpendecular distance from point.
  public func distance(from point: CGPoint) -> CGFloat {
    let mm = -(1&/m)
    let bb = point.y - (mm * point.x)
    let slope = Slope(m: mm, b: bb)
    let inter = intersection(with: slope)
    return lengthBetween(p1: point, p2: inter)
  }

  /// Calculates the intersection point with another slope.
  ///
  /// - Parameter slope: Another slope we want to calculate intersection point.
  /// - Returns: Returns the intersection point with given slope.
  public func intersection(with slope: Slope) -> CGPoint {
    let x = (slope.b - b) &/ (slope.m - m)
    let y = (m * x) + b
    return CGPoint(x: x, y: y)
  }

  /// Calculates the euclidean length between two points.
  ///
  /// - Parameters:
  ///   - p1: First point.
  ///   - p2: Second point.
  /// - Returns: Returns the euclidean lenght.
  public func lengthBetween(p1: CGPoint, p2: CGPoint) -> CGFloat {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
  }
}

/// Customised swipe gesture with extra parameters like start point, duration, velocity, distance, force etc.
/// Designed for one finger swipe only.
public class FlickGestureRecognizer: UIGestureRecognizer {

  /// Starting position of swipe in gesture view.
  public var startPoint: CGPoint = .zero

  /// Current position of swipe in gesture view.
  public var currentPoint: CGPoint = .zero

  /// 3D Touch Force of swipe on start
  public var force: CGFloat?

  /// Treshold of lineer swipe to fail.
  public var swipeLineThreshold: CGFloat = 10

  /// Starting time of gesture. Used to calculate duration and velocity.
  private var startTime = Date()

  /// Time of last update. Used to calculate duration and velocity.
  private var currentTime = Date()

  /// Direction vector of start position to current position in gesture view.
  public var direction: CGVector {
    return CGVector(dx: currentPoint.x - startPoint.x, dy: currentPoint.x - startPoint.x)
  }

  /// Current velocity of swipe between starting position and current position in gesture view.
  public var velocity: CGFloat {
    let length = sqrt(pow(direction.dx, 2) * pow(direction.dy, 2))
    return length / CGFloat(duration)
  }

  /// Current duration of swipe since starting gesture. Used to calculate velocity of swipe.
  public var duration: TimeInterval {
    return currentTime.timeIntervalSince(startTime)
  }

  /// Reference of previous touch points to control lineer swipe.
  private var touchPoints: [CGPoint] = []

  public override var state: UIGestureRecognizerState {
    didSet {
      switch state {
      case .failed:
        startPoint = .zero
        currentPoint = .zero
        startTime = Date()
        currentTime = Date()
        force = nil
        touchPoints = []
      default:
        return
      }
    }
  }

  // MARK: - Touch Updates

  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    startPoint = touches.first?.location(in: view) ?? .zero
    currentPoint = touches.first?.location(in: view) ?? .zero
    startTime = Date()
    currentTime = Date()
    force = nil
    touchPoints = [currentPoint]
    state = touches.count > 1 ? .failed : .began
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    let position = touches.first?.location(in: view) ?? .zero
    currentTime = Date()
    
    if #available(iOS 9.0, *) {
      force = force == nil ? touches.first?.force : force
    } else {
      force = nil
    }

    // Check if swipe is lineer
    let slope = Slope(p1: startPoint, p2: position)
    if slope.distance(from: position) <= swipeLineThreshold || touchPoints.count > 1 {
      currentPoint = position
      touchPoints.append(currentPoint)
      state = .changed
    } else {
      state = .failed
    }
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)
    currentPoint = touches.first?.location(in: view) ?? .zero
    currentTime = Date()
    touchPoints.append(currentPoint)
    state = .ended
  }

  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)
    state = .cancelled
  }

  // MARK: - CustomStringConvertible

  public override var description: String {
    var stateString = ""
    switch state {
    case .began: stateString = "began"
    case .cancelled: stateString = "cancelled"
    case .changed: stateString = "changed"
    case .ended: stateString = "ended"
    case .failed: stateString = "failed"
    case .possible: stateString = "possible"
    }

    return "SwipeKitGestureRecognizer:\n\t- State: \(stateString)\n\t- Start point: \(startPoint) \n\t- Current point: \(currentPoint)\n\t- Direction: \(direction)\n\t- Velocity: \(velocity)\n\t- Duration: \(duration)"
  }
}
