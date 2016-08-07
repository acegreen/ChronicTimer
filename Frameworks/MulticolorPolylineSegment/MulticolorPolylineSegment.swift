/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import MapKit

class MulticolorPolylineSegment: MKPolyline {
  var color: UIColor?

  class func colorSegments(forLocations locations: [CLLocation]) -> [MulticolorPolylineSegment] {
    var colorSegments = [MulticolorPolylineSegment]()

    // RGB for Red (slowest)
    let red   = (r: 1.0, g: 20.0 / 255.0, b: 44.0 / 255.0)

    // RGB for Yellow (middle)
    let yellow = (r: 1.0, g: 215.0 / 255.0, b: 0.0)

    // RGB for Green (fastest)
    let green  = (r: 0.0, g: 146.0 / 255.0, b: 78.0 / 255.0)

    let (speeds, minSpeed, maxSpeed) = allSpeeds(forLocations: locations)

    // now knowing the slowest+fastest, we can get mean too
    let meanSpeed = (minSpeed + maxSpeed)/2

    for i in 1..<locations.count {
      let l1 = locations[i-1]
      let l2 = locations[i]

      var coords = [CLLocationCoordinate2D]()

      coords.append(CLLocationCoordinate2D(latitude: l1.coordinate.latitude, longitude: l1.coordinate.longitude))
      coords.append(CLLocationCoordinate2D(latitude: l2.coordinate.latitude, longitude: l2.coordinate.longitude))

      let speed = speeds[i-1]
      var color = UIColor.black

      if speed < minSpeed { // Between Red & Yellow
        let ratio = (speed - minSpeed) / (meanSpeed - minSpeed)
        let r = CGFloat(red.r + ratio * (yellow.r - red.r))
        let g = CGFloat(red.g + ratio * (yellow.g - red.g))
        let b = CGFloat(red.r + ratio * (yellow.r - red.r))
        color = UIColor(red: r, green: g, blue: b, alpha: 1)
      }
      else { // Between Yellow & Green
        let ratio = (speed - meanSpeed) / (maxSpeed - meanSpeed)
        let r = CGFloat(yellow.r + ratio * (green.r - yellow.r))
        let g = CGFloat(yellow.g + ratio * (green.g - yellow.g))
        let b = CGFloat(yellow.b + ratio * (green.b - yellow.b))
        color = UIColor(red: r, green: g, blue: b, alpha: 1)
      }

      let segment = MulticolorPolylineSegment(coordinates: &coords, count: coords.count)
      segment.color = color
      colorSegments.append(segment)
    }

    return colorSegments
  }

  private class func allSpeeds(forLocations locations: [CLLocation]) -> (speeds: [Double], minSpeed: Double, maxSpeed: Double) {
    // Make Array of all speeds. Find slowest and fastest
    var speeds = [Double]()
    var minSpeed = DBL_MAX
    var maxSpeed = 0.0

    for i in 1..<locations.count {
      let l1 = locations[i-1]
      let l2 = locations[i]

      let cl1 = CLLocation(latitude: l1.coordinate.latitude, longitude: l1.coordinate.longitude)
      let cl2 = CLLocation(latitude: l2.coordinate.latitude, longitude: l2.coordinate.longitude)

      let distance = cl2.distance(from: cl1)
      let time = l2.timestamp.timeIntervalSince(l1.timestamp)
      let speed = distance/time

      minSpeed = min(minSpeed, speed)
      maxSpeed = max(maxSpeed, speed)

      speeds.append(speed)
    }

    return (speeds, minSpeed, maxSpeed)
  }

}
