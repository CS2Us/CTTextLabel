//
//  PolarisTextView.swift
//  CoreTextDemo
//
//  Created by guoyiyuan on 2018/11/27.
//  Copyright © 2018 guoyiyuan. All rights reserved.
//

import Foundation
import UIKit
import CoreText
import SnapKit

public enum CTTextVerticalAlignment: UInt8 {
	case top
	case center
	case bottom
}

private enum CTTextRunGlyphDrawMode: UInt8 {
	case horizontal
	case verticalRotate
	case verticalRotateMove
}

private struct CTRunGlyphInfo {
	public fileprivate(set) var glyphRangeRun: NSRange = NSMakeRange(0, 0)
	public fileprivate(set) var drawMode: CTTextRunGlyphDrawMode = CTTextRunGlyphDrawMode.horizontal
}

private struct CTLineInfo {
	public fileprivate(set) var ascent: CGFloat = 0
	public fileprivate(set) var descent: CGFloat = 0
	public fileprivate(set) var leading: CGFloat = 0
	public fileprivate(set) var lineWidth: CGFloat = 0
	public fileprivate(set) var range: CFRange = CFRange()
	public fileprivate(set) var trailingWhitespaceWidth: CGFloat = 0
	public fileprivate(set) var firstGlyphPos: CGPoint = CGPoint.zero
	public fileprivate(set) var bounds: CGRect = CGRect.zero
}

private func AboutCTLine(_ ctline: CTLine, vertical: Bool, at position: CGPoint) -> CTLineInfo {
	var info = CTLineInfo.init()
	info.lineWidth = CGFloat(CTLineGetTypographicBounds(ctline, &info.ascent, &info.descent, &info.leading))
	info.range = CTLineGetStringRange(ctline)
	info.trailingWhitespaceWidth = CGFloat(CTLineGetTrailingWhitespaceWidth(ctline))
	let runs = CTLineGetGlyphRuns(ctline)
	if CFArrayGetCount(runs) > 0 {
		let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, 0), to: CTRun.self)
		CTRunGetPositions(run, CFRange(location: 0, length: 1), &info.firstGlyphPos);
	}
	var bounds = CGRect.zero
	if vertical {
		bounds = CGRect(x: position.x - info.descent, y: position.y, width: info.ascent + info.descent, height: info.lineWidth)
		bounds.origin.y += info.firstGlyphPos.x
	} else {
		bounds = CGRect(x: position.x, y: position.y - info.descent, width: info.lineWidth, height: info.ascent + info.descent)
		bounds.origin.x += info.firstGlyphPos.x
	}
	info.bounds = bounds
	return info
}

private func AboutCTPath(_ rect: CGRect, path: CGPath?, exclusionPaths: [UIBezierPath]?) -> CGPath? {
	var transform = CGAffineTransform.init(scaleX: 1, y: -1)
	var calculateRect = CGRect(origin: .zero, size: rect.size)
	let calculatePath = CGPath(rect: calculateRect, transform: nil)
	var addedPath: CGMutablePath?
	switch (path, exclusionPaths) {
	case (.some, .none):
		guard path!.isRect(&calculateRect) else { return nil }
		return CGPath.init(rect: calculateRect, transform: &transform)
	case (.none, .some):
		addedPath = path!.mutableCopy()
	case (.some, .some):
		guard path!.isRect(&calculateRect) else { return nil }
		addedPath = CGPath(rect: rect, transform: nil).mutableCopy()
	default: return calculatePath
	}
	for temp in exclusionPaths! {
		addedPath!.addPath(temp.cgPath)
	}
	calculateRect = addedPath!.boundingBox
	return CGPath(rect: calculateRect, transform: &transform)
}

private func AboutCTVerticalFormRotateAndMoveCharacterSet() -> NSCharacterSet {
	let c_set = NSMutableCharacterSet()
	c_set.addCharacters(in: "，；。、．")
	return c_set
}

private func AboutCTVerticalNotRotateAndMoveCharacterSet() -> NSCharacterSet {
	let c_set = NSMutableCharacterSet()
	c_set.addCharacters(in: NSMakeRange(0x300E, 1)) // 『
	c_set.addCharacters(in: NSMakeRange(0x300F, 1)) //  』
	c_set.addCharacters(in: NSMakeRange(0x301D, 1)) // 〝
	c_set.addCharacters(in: NSMakeRange(0x301E, 1)) //  〞
	c_set.addCharacters(in: NSMakeRange(0x3003, 1)) //  〃
	c_set.addCharacters(in: NSMakeRange(0x300A, 1)) // 《
	c_set.addCharacters(in: NSMakeRange(0x300B, 1)) //  》
	c_set.addCharacters(in: NSMakeRange(0x300C, 1)) // 「
	c_set.addCharacters(in: NSMakeRange(0x300D, 1)) //  」
	
	return c_set
}

private func AboutCTVerticalFormRotateCharacterSet() -> NSCharacterSet {
	let c_set = NSMutableCharacterSet()
	c_set.addCharacters(in: NSMakeRange(0x1100, 256)) // Hangul Jamo
	c_set.addCharacters(in: NSMakeRange(0x2460, 160)) // Enclosed Alphanumerics
	c_set.addCharacters(in: NSMakeRange(0x2600, 256)) // Miscellaneous Symbols
	c_set.addCharacters(in: NSMakeRange(0x2700, 192)) // Dingbats
	c_set.addCharacters(in: NSMakeRange(0x2E80, 128)) // CJK Radicals Supplement
	c_set.addCharacters(in: NSMakeRange(0x2F00, 224)) // Kangxi Radicals
	c_set.addCharacters(in: NSMakeRange(0x2FF0, 16)) // Ideographic Description Characters
	c_set.addCharacters(in: NSMakeRange(0x3000, 64)) // CJK Symbols and Punctuation
	c_set.addCharacters(in: NSMakeRange(0x3008, 10))
	c_set.addCharacters(in: NSMakeRange(0x3014, 12))
	c_set.addCharacters(in: NSMakeRange(0x3040, 96)) // Hiragana
	c_set.addCharacters(in: NSMakeRange(0x30A0, 96)) // Katakana
	c_set.addCharacters(in: NSMakeRange(0x3100, 48)) // Bopomofo
	c_set.addCharacters(in: NSMakeRange(0x3130, 96)) // Hangul Compatibility Jamo
	c_set.addCharacters(in: NSMakeRange(0x3190, 16)) // Kanbun
	c_set.addCharacters(in: NSMakeRange(0x31A0, 32)) // Bopomofo Extended
	c_set.addCharacters(in: NSMakeRange(0x31C0, 48)) // CJK Strokes
	c_set.addCharacters(in: NSMakeRange(0x31F0, 16)) // Katakana Phonetic Extensions
	c_set.addCharacters(in: NSMakeRange(0x3200, 256)) // Enclosed CJK Letters and Months
	c_set.addCharacters(in: NSMakeRange(0x3300, 256)) // CJK Compatibility
	c_set.addCharacters(in: NSMakeRange(0x3400, 2582)) // CJK Unified Ideographs Extension A
	c_set.addCharacters(in: NSMakeRange(0x4E00, 20941)) // CJK Unified Ideographs
	c_set.addCharacters(in: NSMakeRange(0xAC00, 11172)) // Hangul Syllables
	c_set.addCharacters(in: NSMakeRange(0xD7B0, 80)) // Hangul Jamo Extended-B
	c_set.addCharacters(in: "") // U+F8FF (Private Use Area)
	c_set.addCharacters(in: NSMakeRange(0xF900, 512)) // CJK Compatibility Ideographs
	c_set.addCharacters(in: NSMakeRange(0xFE10, 16)) // Vertical Forms
	c_set.addCharacters(in: NSMakeRange(0xFF00, 240)) // Halfwidth and Fullwidth Forms
	c_set.addCharacters(in: NSMakeRange(0x1F200, 256)) // Enclosed Ideographic Supplement
	c_set.addCharacters(in: NSMakeRange(0x1F300, 768)) // Enclosed Ideographic Supplement
	c_set.addCharacters(in: NSMakeRange(0x1F600, 80)) // Emoticons (Emoji)
	c_set.addCharacters(in: NSMakeRange(0x1F680, 128)) // Transport and Map Symbols
	return c_set
}

public class CTTextLabel: UIView {
	private let defaultMaxContentSize: CGSize = CGSize(width: 0x100000, height: 0x100000)
	
	public typealias CTTextCallback = () -> NSAttributedString
	
	public var vertical: Bool = false
	public var numberOfLines: Int = 0;
	public var contentInset: UIEdgeInsets = UIEdgeInsets.zero
	public var pathFillEvenOdd: Bool = true
	public var preferredMaxLayoutLimit: CGFloat = 0
	public var path: CGPath?
	public var exclusionPaths: [UIBezierPath]?
	public var verticalAlignment: CTTextVerticalAlignment = .center
	public var text: NSAttributedString! { didSet { self.setNeedsRedraw() }}
	public var textCb: CTTextCallback! { didSet { self.text = self.textCb() }}
	
	@inline(__always)
	private func setNeedsRedraw() {
		self.setNeedsDisplay()
		self.invalidateIntrinsicContentSize()
	}
	
	public override func draw(_ rect: CGRect) {
		var ctxSize = bounds.size
		if vertical {
			ctxSize.width = defaultMaxContentSize.width
			ctxSize.height = preferredMaxLayoutLimit > 0 ? preferredMaxLayoutLimit : bounds.size.height
		} else {
			ctxSize.height = defaultMaxContentSize.height
			ctxSize.width = preferredMaxLayoutLimit > 0 ? preferredMaxLayoutLimit : bounds.size.width
		}
		var rect = CGRect(origin: CGPoint.zero, size: ctxSize)
		rect = rect.inset(by: contentInset)
		
		let ctPath = CGPath(rect: rect.applying(CGAffineTransform.init(scaleX: 1, y: -1)), transform: nil)
		
		let frameAttrs = NSMutableDictionary()
		if vertical { frameAttrs[kCTFrameProgressionAttributeName] = CTFrameProgression.rightToLeft.rawValue }
		if pathFillEvenOdd { frameAttrs[kCTFramePathFillRuleAttributeName] = CTFramePathFillRule.evenOdd.rawValue  }
		else { frameAttrs[kCTFramePathFillRuleAttributeName] = CTFramePathFillRule.windingNumber.rawValue }
		let ctSetter = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
		let range = CFRange(location: 0, length: text.length)
		let ctFrame = CTFramesetterCreateFrame(ctSetter, range, ctPath, frameAttrs)
		let ctLines = CTFrameGetLines(ctFrame)
		let lineCount = CFArrayGetCount(ctLines)
		var lineOrigins = [CGPoint](repeating: .zero, count: lineCount)
		CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, lineCount), &lineOrigins)
		var actualBoundingRect = CGRect.zero
		var actualBoundingSize = CGSize.zero
		var actualLinePosition = [CGPoint]()
		var actualLineRanges = [[[CTRunGlyphInfo]]]()
		for lineIndex in 0..<lineCount {
			let ctLine = unsafeBitCast(CFArrayGetValueAtIndex(ctLines, lineIndex), to: CTLine.self)
			let ctRuns = CTLineGetGlyphRuns(ctLine)
			if CFArrayGetCount(ctRuns) == 0 { continue }
			let ctLineOrigin = lineOrigins[lineIndex]
			var position = CGPoint.zero
			position.x = rect.origin.x + ctLineOrigin.x
			position.y = rect.size.height + rect.origin.y - ctLineOrigin.y
			if numberOfLines > 0, lineIndex > numberOfLines {
				break
			}
			let lineBounds = AboutCTLine(ctLine, vertical: vertical, at: position).bounds
			if lineIndex == 0 {
				actualBoundingRect = lineBounds
			}
			actualBoundingRect = actualBoundingRect.union(lineBounds)
			actualBoundingSize = actualBoundingRect.size
			actualLinePosition.append(position)
		}
		
		if vertical {
			let rotateCharset = AboutCTVerticalFormRotateCharacterSet()
			let rotateMoveCharset = AboutCTVerticalFormRotateAndMoveCharacterSet()
			let notRotateCharset = AboutCTVerticalNotRotateAndMoveCharacterSet()
			
			for lineIndex in 0..<lineCount {
				let ctLine = unsafeBitCast(CFArrayGetValueAtIndex(ctLines, lineIndex) , to: CTLine.self)
				let ctRuns = CTLineGetGlyphRuns(ctLine)
				let runCount = CFArrayGetCount(ctRuns)
				var lineRunRanges = [[CTRunGlyphInfo]]()
				if runCount <= 0 { continue }
				for runIndex in 0..<runCount {
					let ctRun = unsafeBitCast(CFArrayGetValueAtIndex(ctRuns, runIndex) , to: CTRun.self)
					var runRanges = [CTRunGlyphInfo]()
					let glyphCount = CTRunGetGlyphCount(ctRun)
					if glyphCount <= 0 { continue }
					
					var runStrIndices = [CFIndex](repeating: 0, count: glyphCount+1)
					CTRunGetStringIndices(ctRun, CFRangeMake(0, 0), &runStrIndices)
					let runStrRange = CTRunGetStringRange(ctRun)
					runStrIndices[glyphCount] = runStrRange.location + runStrRange.length
					let runAttrs = CTRunGetAttributes(ctRun)
					let ctFont = unsafeBitCast(CFDictionaryGetValue(runAttrs, unsafeBitCast(kCTFontAttributeName, to: UnsafeRawPointer.self)), to: CTFont.self)
					let isColorGlyph = (CTFontGetSymbolicTraits(ctFont).rawValue & CTFontSymbolicTraits.traitColorGlyphs.rawValue) != 0
					
					var prevIndex = 0
					var prevMode = CTTextRunGlyphDrawMode.horizontal
					for glyphIndex in 0..<glyphCount {
						var glyphRotate = false
						var glyphRotateMove = false
						let runStrLen = runStrIndices[glyphIndex + 1] - runStrIndices[glyphIndex]
						if isColorGlyph {
							glyphRotate = true
						} else if runStrLen == 1 {
							let character = (text.string as NSString).character(at: runStrIndices[glyphIndex])
							glyphRotate = notRotateCharset.characterIsMember(character) ? false : rotateCharset.characterIsMember(character)
							if glyphRotate {
								glyphRotateMove = rotateMoveCharset.characterIsMember(character)
							}
						} else if runStrLen > 1 {
							let glyphStr = (text.string as NSString).substring(with: NSMakeRange(runStrIndices[glyphIndex], runStrLen))
							glyphRotate = glyphStr.rangeOfCharacter(from: notRotateCharset as CharacterSet) != nil ? false : glyphStr.rangeOfCharacter(from: rotateCharset as CharacterSet) != nil
							if glyphRotate {
								glyphRotateMove = glyphStr.rangeOfCharacter(from: rotateMoveCharset as CharacterSet) != nil
							}
						}
						
						let mode = glyphRotateMove ? CTTextRunGlyphDrawMode.verticalRotateMove : (glyphRotate ? CTTextRunGlyphDrawMode.verticalRotate : CTTextRunGlyphDrawMode.horizontal)
						if glyphIndex == 0 {
							prevMode = mode
						} else if (mode != prevMode) {
							var glyphRange = CTRunGlyphInfo()
							glyphRange.glyphRangeRun = NSMakeRange(prevIndex, glyphIndex - prevIndex)
							glyphRange.drawMode = prevMode
							runRanges.append(glyphRange)
							
							prevIndex = glyphIndex
							prevMode = mode
						}
					}
					
					if prevIndex < glyphCount {
						var glyphRange = CTRunGlyphInfo()
						glyphRange.glyphRangeRun = NSMakeRange(prevIndex, glyphCount - prevIndex)
						glyphRange.drawMode = prevMode
						runRanges.append(glyphRange)
					}
					lineRunRanges.append(runRanges)
				}
				actualLineRanges.append(lineRunRanges)
			}
		}
		
		var point = CGPoint.zero
		switch verticalAlignment {
		case .center:
			if vertical {
				point.x = -(bounds.size.width - actualBoundingSize.width) * 0.5
			} else {
				point.y = (bounds.size.height - actualBoundingSize.height) * 0.5
			}
		case .bottom:
			if vertical {
				point.x = -(bounds.size.width - actualBoundingSize.width)
			} else {
				point.y = bounds.size.height - actualBoundingSize.height
			}
			
		default: break
		}
		
		let context = UIGraphicsGetCurrentContext()
		guard let ctx = context else { return }
		ctx.saveGState()
		ctx.translateBy(x: point.x, y: point.y)
		ctx.translateBy(x: 0, y: bounds.size.height)
		ctx.scaleBy(x: 1, y: -1)
		
		let verticalOffset = vertical ? bounds.size.width - rect.width : 0
		let actualLineCount = numberOfLines > lineCount ? lineCount : numberOfLines
		for lineIndex in 0..<actualLineCount {
			let ctLine = unsafeBitCast(CFArrayGetValueAtIndex(ctLines, lineIndex) , to: CTLine.self)
			let posX = actualLinePosition[lineIndex].x + verticalOffset
			let posY = bounds.size.height - actualLinePosition[lineIndex].y
			let ctRuns = CTLineGetGlyphRuns(ctLine)
			for runIndex in 0..<CFArrayGetCount(ctRuns) {
				let ctRun = unsafeBitCast(CFArrayGetValueAtIndex(ctRuns, runIndex) , to: CTRun.self)
				ctx.textMatrix = CGAffineTransform.identity
				ctx.textPosition = CGPoint(x: posX, y: posY)
				//				let runTextMatrix = CTRunGetTextMatrix(ctRun)
				//				let runTextMatrixIsID = runTextMatrix.isIdentity
				let runAttrs = CTRunGetAttributes(ctRun)
				
				let runFont = unsafeBitCast(CFDictionaryGetValue(runAttrs, unsafeBitCast(kCTFontAttributeName, to: UnsafeRawPointer.self)), to: CTFont.self)
				let glyphCount = CTRunGetGlyphCount(ctRun)
				if glyphCount <= 0 { continue }
				
				var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
				var glyphPositions = [CGPoint](repeating: CGPoint.zero, count: glyphCount)
				CTRunGetGlyphs(ctRun, CFRangeMake(0, 0), &glyphs)
				CTRunGetPositions(ctRun, CFRangeMake(0, 0), &glyphPositions)
				let fillColor = unsafeBitCast(CFDictionaryGetValue(runAttrs, unsafeBitCast(kCTForegroundColorAttributeName, to: UnsafeRawPointer.self)), to: CGColor.self)
				let strokeWidth = 0.00
				var strokeColor = unsafeBitCast(CFDictionaryGetValue(runAttrs, unsafeBitCast(kCTStrokeColorAttributeName, to: UnsafeRawPointer.self)), to: CGColor.self)
				
				
				ctx.saveGState()
				ctx.setFillColor(fillColor)
				if strokeWidth == 0  {
					ctx.setTextDrawingMode(.fill)
				} else {
					if strokeColor.numberOfComponents == 0 {
						strokeColor = fillColor
					}
					ctx.setStrokeColor(strokeColor)
					//					ctx.setLineWidth(CTFontGetSize(runFont) * CGFloat(fabsf(strokeWidth * 0.01)))
					if strokeWidth > 0 {
						ctx.setTextDrawingMode(.stroke)
					} else {
						ctx.setTextDrawingMode(.fillStroke)
					}
				}
				
				if vertical {
					var runStrIndex = [CFIndex](repeating: 0, count: glyphCount + 1)
					CTRunGetStringIndices(ctRun, CFRangeMake(0, 0), &runStrIndex)
					let runStrRange = CTRunGetStringRange(ctRun)
					runStrIndex[glyphCount] = runStrRange.location + runStrRange.length
					var glyphAdvances = [CGSize](repeating: CGSize.zero, count: glyphCount)
					CTRunGetAdvances(ctRun, CFRangeMake(0, 0), &glyphAdvances)
					let ascent = CTFontGetAscent(runFont)
					let descent = CTFontGetDescent(runFont)
					var zeroPoint = [CGPoint](repeating: CGPoint.zero, count: 1)
					
					let lineRunRange = actualLineRanges[lineIndex]
					let runRange = lineRunRange[runIndex]
					
					for oneRange in runRange {
						let range = oneRange.glyphRangeRun
						let rangeMax = range.location + range.length
						let mode = oneRange.drawMode
						
						for glyphIndex in oneRange.glyphRangeRun.location..<rangeMax {
							ctx.saveGState()
							ctx.textMatrix = CGAffineTransform.identity
							
							if mode.rawValue != 0 {
								let ofs = (ascent - descent) * 0.5
								let w = glyphAdvances[glyphIndex].width * 0.5
								var x = actualLinePosition[lineIndex].x + verticalOffset + glyphPositions[glyphIndex].y + (ofs - w)
								var y = -actualLinePosition[lineIndex].y + bounds.size.height - glyphPositions[glyphIndex].x - (ofs + w)
								if mode == .verticalRotateMove {
									x += ofs
									y += w - ofs
								}
								ctx.textPosition = CGPoint(x: x, y: y)
							} else {
								let ctRunAttrs = CTRunGetAttributes(ctRun)
								let p_kern_key = Unmanaged.passUnretained(kCTKernAttributeName).toOpaque()
								let p_kern_val = CFDictionaryGetValue(ctRunAttrs, p_kern_key)
								let p_kern = Unmanaged<CFNumber>.fromOpaque(p_kern_val!).takeUnretainedValue()
								var kern: CGFloat = 0
								CFNumberGetValue(p_kern, .cgFloatType, &kern)
								ctx.rotate(by: CGFloat(-90 * Double.pi / 180))
								ctx.textPosition = CGPoint(x: actualLinePosition[lineIndex].y - bounds.size.height + glyphPositions[glyphIndex].x + kern * 0.5, y: actualLinePosition[lineIndex].x + verticalOffset + glyphPositions[glyphIndex].y - kern * 0.5)
							}
							
							
							let isColorGlyph = (CTFontGetSymbolicTraits(runFont).rawValue & CTFontSymbolicTraits.traitColorGlyphs.rawValue) != 0
							let copy_glyphs = [CGGlyph](repeating: glyphs[glyphIndex], count: 1)
							if isColorGlyph {
								CTFontDrawGlyphs(runFont, copy_glyphs, &zeroPoint, 1, ctx)
							} else {
								let cgFont = CTFontCopyGraphicsFont(runFont, nil)
								ctx.setFont(cgFont)
								ctx.setFontSize(CTFontGetSize(runFont))
								ctx.showGlyphs(copy_glyphs, at: zeroPoint)
							}
							ctx.restoreGState()
						}
					}
				} else {
					let isColorGlyph = (CTFontGetSymbolicTraits(runFont).rawValue & CTFontSymbolicTraits.traitColorGlyphs.rawValue) != 0
					let copy_glyphs = glyphs
					if isColorGlyph {
						CTFontDrawGlyphs(runFont, copy_glyphs, &glyphPositions, glyphCount, ctx)
					} else {
						let cgFont = CTFontCopyGraphicsFont(runFont, nil)
						ctx.setFont(cgFont)
						ctx.setFontSize(CTFontGetSize(runFont))
						ctx.showGlyphs(copy_glyphs, at: glyphPositions)
					}
				}
			}
		}
	}
}
