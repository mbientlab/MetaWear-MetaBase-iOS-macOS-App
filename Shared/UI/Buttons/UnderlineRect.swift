// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct UnderlineRect: InsettableShape, Animatable {

    var cornerRadius: CGFloat
    var percent: CGFloat
    var inset: CGFloat = 0

    var animatableData: CGFloat {
        get { percent }
        set { percent = newValue }
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.inset += amount
        return shape
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: inset, dy: inset)
        let lineStart = CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY)
        let lineEnd = CGPoint(x: rect.minX + cornerRadius, y: rect.maxY)

        var line = Path()
        line.move(to: lineStart)
        line.addLine(to: lineEnd)

        let left = makeCurve(onLeft: true, in: rect).trimmedPath(from: 0, to: percent)
        let right = makeCurve(onLeft: false, in: rect).trimmedPath(from: 0, to: percent)

        line.addPath(left)
        line.addPath(right)
        return line
    }

    func makeCurve(onLeft: Bool, in rect: CGRect) -> Path {
        let direction: CGFloat = onLeft ? 1 : -1
        let x = onLeft ? rect.minX : rect.maxX

        let lineEnd =             CGPoint(x: x + cornerRadius * direction, y: rect.maxY)
        let bottomCornerEnd =     CGPoint(x: x, y: rect.maxY - cornerRadius)
        let bottomCornerControl = CGPoint(x: x, y: rect.maxY)
        let topCornerStart =      CGPoint(x: x, y: rect.minY + cornerRadius)
        let topCornerEnd =        CGPoint(x: x + cornerRadius * direction, y: rect.minY)
        let topCornerControl =    CGPoint(x: x, y: rect.minY)
        let terminus =            CGPoint(x: rect.midX, y: rect.minY)

        var path = Path()
        path.move(to: lineEnd)
        path.addQuadCurve(to: bottomCornerEnd, control: bottomCornerControl)
        path.addLine(to: topCornerStart)
        path.addQuadCurve(to: topCornerEnd, control: topCornerControl)
        path.addLine(to: terminus)
        return path
    }
}
