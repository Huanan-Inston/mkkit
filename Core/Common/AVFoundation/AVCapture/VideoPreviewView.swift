//
//  VideoPreviewView.swift
//  MKKit
//
//  Created by MK on 2023/12/12.
//  https://developer.apple.com/documentation/avfoundation/capture_setup/avcambarcode_detecting_barcodes_and_faces

import AVFoundation
import Foundation
import OpenCombine
import UIKit

// MARK: - VideoPreviewView

open class VideoPreviewView: UIView {
    override open class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    public var canShowRegionOfInterest: Bool = false
    public var canShowMask: Bool = false

    private let regionOfInterestSubject: CurrentValueSubject<CGRect, Never> = .init(.null)
    public private(set) lazy var regionOfInterestPublihser = regionOfInterestSubject.removeDuplicatesDropAndDebounce(0, debounce: 0.1).eraseToAnyPublisher()

    public lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = layer as! AVCaptureVideoPreviewLayer

    public private(set) lazy var drawLayer = CALayer()

    public var minimumRegionOfInterestSize: CGFloat = 50

    private lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        layer.fillColor = UIColor.black.cgColor
        layer.opacity = 0.6
        return layer
    }()

    private lazy var regionOfInterestOutline: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(rect: regionOfInterest).cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.yellow.cgColor
        return layer
    }()

    override open func layoutSubviews() {
        super.layoutSubviews()

        // Disable CoreAnimation actions so that the positions of the sublayers immediately move to their new position.
        guard canShowMask || canShowRegionOfInterest else {
            return
        }

        if drawLayer.superlayer == nil {
            layer.addSublayer(drawLayer)
        }
        drawLayer.frame = bounds

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if canShowMask {
            if maskLayer.superlayer == nil {
                drawLayer.addSublayer(maskLayer)
            }
        }

        if canShowRegionOfInterest {
            if regionOfInterestOutline.superlayer == nil {
                drawLayer.addSublayer(regionOfInterestOutline)
            }

            // Create the path for the mask layer. We use the even odd fill rule so that the region of interest does not have a fill color.
            let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
            path.append(UIBezierPath(rect: regionOfInterest))
            path.usesEvenOddFillRule = true
            maskLayer.path = path.cgPath

            regionOfInterestOutline.path = CGPath(rect: regionOfInterest, transform: nil)
        }

        CATransaction.commit()
    }
}

public extension VideoPreviewView {
    func showDrawLayer(_ show: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawLayer.isHidden = !show
        CATransaction.commit()
    }

    private(set) var regionOfInterest: CGRect {
        get {
            regionOfInterestSubject.value
        }

        set {
            if newValue != regionOfInterestSubject.value {
                regionOfInterestSubject.value = newValue

                setNeedsLayout()
            }
        }
    }

    var session: AVCaptureSession? {
        get {
            videoPreviewLayer.session
        }

        set {
            videoPreviewLayer.session = newValue
        }
    }

    /**
     Updates the region of interest with a proposed region of interest ensuring
     the new region of interest is within the bounds of the video preview. When
     a new region of interest is set, the region of interest is redrawn.
     */
    @objc func setRegionOfInterestWithProposedRegionOfInterest(_ proposedRegionOfInterest: CGRect) {
        // We standardize to ensure we have positive widths and heights with an origin at the top left.
        let videoPreviewRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect:
            CGRect(x: 0, y: 0, width: 1, height: 1)
        ).standardized

        /*
         Intersect the video preview view with the view's frame to only get
         the visible portions of the video preview view.
         */
        let visibleVideoPreviewRect = videoPreviewRect.intersection(bounds)

        let oldRegionOfInterest = regionOfInterest
        var newRegionOfInterest = proposedRegionOfInterest.standardized

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        if !visibleVideoPreviewRect.contains(newRegionOfInterest.origin) {
            xOffset = max(visibleVideoPreviewRect.minX - newRegionOfInterest.minX, CGFloat(0))
            yOffset = max(visibleVideoPreviewRect.minY - newRegionOfInterest.minY, CGFloat(0))
        }

        if !visibleVideoPreviewRect.contains(CGPoint(x: visibleVideoPreviewRect.maxX, y: visibleVideoPreviewRect.maxY)) {
            xOffset = min(visibleVideoPreviewRect.maxX - newRegionOfInterest.maxX, xOffset)
            yOffset = min(visibleVideoPreviewRect.maxY - newRegionOfInterest.maxY, yOffset)
        }

        newRegionOfInterest = newRegionOfInterest.offsetBy(dx: xOffset, dy: yOffset)

        // Clamp the size when the region of interest is being resized.
        newRegionOfInterest = visibleVideoPreviewRect.intersection(newRegionOfInterest)

        // Fix a minimum width of the region of interest.
        if proposedRegionOfInterest.size.width < minimumRegionOfInterestSize {
            newRegionOfInterest.origin = oldRegionOfInterest.origin
            newRegionOfInterest.size.width = minimumRegionOfInterestSize
        }

        // Fix a minimum height of the region of interest.
        if proposedRegionOfInterest.size.height < minimumRegionOfInterestSize {
            newRegionOfInterest.origin = oldRegionOfInterest.origin
            newRegionOfInterest.size.height = minimumRegionOfInterestSize
        }

        regionOfInterest = newRegionOfInterest
    }
}