//
//  GridController.swift
//  StencilCam
//
//  Created by Mike on 2019-12-24.
//  Copyright © 2019 Mike. All rights reserved.
//

import UIKit

class GridView: UIView {
    
    var rows: Int = 4
    var columns: Int = 2
    var lineWidth: CGFloat = 1.0
    var lineColor: UIColor = UIColor.white
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.cgColor)
        
        let columnWidth = Int(rect.width) / (columns + 1)
        for i in 1...columns {
            var startPoint = CGPoint.zero
            var endPoint = CGPoint.zero
            startPoint.x = CGFloat(columnWidth * i)
            startPoint.y = 0.0
            endPoint.x = startPoint.x
            endPoint.y = frame.size.height
            context.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
            context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            context.strokePath()
        }
        
        let rowHeight = Int(rect.height) / (rows + 1)
        for j in 1...rows {
            var startPoint = CGPoint.zero
            var endPoint = CGPoint.zero
            startPoint.x = 0.0
            startPoint.y = CGFloat(rowHeight * j)
            endPoint.x = frame.size.width
            endPoint.y = startPoint.y
            context.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
            context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
            context.strokePath()
        }
    }
}
