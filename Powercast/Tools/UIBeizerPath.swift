//
// Based from:
// https://www.ramshandilya.com/blog/draw-smooth-curves/
// - license: https://github.com/Ramshandilya/Bezier/blob/master/LICENSE
//
// Modified quite a bit
//

import Foundation
import UIKit

// swiftlint:disable function_body_length identifier_name cyclomatic_complexity large_tuple
extension UIBezierPath {
    func addCurve(through points: [CGPoint]) {
        guard points.count > 1 else { return }

        guard points.count > 3 else {
            switch points.count {
            case 2:
                let p0 = points[0]
                let p3 = points[1]

                let p1x = (2 * p0.x + p3.x) / 3
                let p1y = (2 * p0.y + p3.y) / 3
                let p2x = (2 * p1x - p0.x)
                let p2y = (2 * p1y - p0.y)

                move(to: p0)
                addCurve(to: p3, controlPoint1: CGPoint(x: p1x, y: p1y), controlPoint2: CGPoint(x: p2x, y: p2y))
            default:
                break
            }
            return
        }

        let count = points.count - 1
        var p1s: [CGPoint?] = Array(repeating: nil, count: count)
        var p2s: [CGPoint] = []

        var rhsArray: [CGPoint] = []

        let a: [CGFloat] = [0] + Array(repeating: 1, count: count - 2) + [2]
        var b: [CGFloat] = [2] + Array(repeating: 4, count: count - 2) + [7]
        let c: [CGFloat] = Array(repeating: 1, count: count - 1) + [0]

        for i in 0..<count {
            let x: CGFloat
            let y: CGFloat

            let p0 = points[i]
            let p3 = points[i + 1]

            if i == 0 {
                x = p0.x + 2 * p3.x
                y = p0.y + 2 * p3.y

            } else if i == count-1 {
                x = 8 * p0.x + p3.x
                y = 8 * p0.y + p3.y
            } else {
                x = 4 * p0.x + 2 * p3.x
                y = 4 * p0.y + 2 * p3.y
            }

            rhsArray.append(CGPoint(x: x, y: y))
        }

        for i in 1..<count {
            let x = rhsArray[i].x
            let y = rhsArray[i].y

            let previousX = rhsArray[i - 1].x
            let previousY = rhsArray[i - 1].y

            let m = CGFloat(a[i]/b[i - 1])

            let b1 = b[i] - m * c[i - 1]
            b[i] = b1

            let r2x = x - m * previousX
            let r2y = y - m * previousY

            rhsArray[i] = CGPoint(x: r2x, y: r2y)
        }

        let lastControlPointX = rhsArray[count - 1].x/b[count - 1]
        let lastControlPointY = rhsArray[count - 1].y/b[count - 1]

        p1s[count - 1] = CGPoint(x: lastControlPointX, y: lastControlPointY)

        for i in (0 ..< count - 1).reversed() {
            if let nextControlPoint = p1s[i + 1] {
                let controlPointX = (rhsArray[i].x - c[i] * nextControlPoint.x)/b[i]
                let controlPointY = (rhsArray[i].y - c[i] * nextControlPoint.y)/b[i]

                p1s[i] = CGPoint(x: controlPointX, y: controlPointY)
            }
        }

        for i in 0..<count {
            if i == count-1 {
                let p3 = points[i + 1]

                guard let p1 = p1s[i] else {
                    continue
                }

                let controlPointX = (p3.x + p1.x) / 2
                let controlPointY = (p3.y + p1.y) / 2

                p2s.append(CGPoint(x: controlPointX, y: controlPointY))
            } else {
                let p3 = points[i + 1]

                guard let nextp1 = p1s[i + 1] else {
                    continue
                }

                let controlPointX = 2 * p3.x - nextp1.x
                let controlPointY = 2 * p3.y - nextp1.y

                p2s.append(CGPoint(x: controlPointX, y: controlPointY))
            }
        }

        var curves: [(CGPoint, CGPoint, CGPoint)] = []
        for (index, point) in points.enumerated() {
            if index == count { continue }

            if let p1 = p1s[index] {
                let p2 = p2s[index]
                curves.append((point, p1, p2))
            }
        }

        for (index, (point, _, _)) in curves.enumerated() {
            if index == 0 {
                move(to: point)
            } else {
                let (_, p1, p2) = curves[index - 1]
                addCurve(to: point, controlPoint1: p1, controlPoint2: p2)
            }
        }
    }
}
// swiftlint:enable function_body_length identifier_name cyclomatic_complexity large_tuple
