//
// TietzeTypesetter.swift
//
//
// Created by Christian Tietze on 21/6/19.

import Cocoa


/* This typesetter ensures that paragraph heights nice round numbers so that table view cells have a whole number cell height, and thus draw crisply on non-retina displays */

class TietzeTypesetter: NSATSTypesetter {
    override func beginLine(withGlyphAt glyphIndex: Int) {
        super.beginLine(withGlyphAt: glyphIndex)
    }
    override func endLine(withGlyphRange lineGlyphRange: NSRange) {
        super.endLine(withGlyphRange: lineGlyphRange)
//        print("Ended line\n")
    }
    
    override func getLineFragmentRect(_ lineFragmentRect: UnsafeMutablePointer<NSRect>, usedRect lineFragmentUsedRect: UnsafeMutablePointer<NSRect>, forParagraphSeparatorGlyphRange paragraphSeparatorGlyphRange: NSRange, atProposedOrigin lineOrigin: NSPoint) {
        super.getLineFragmentRect(lineFragmentRect, usedRect: lineFragmentUsedRect, forParagraphSeparatorGlyphRange: paragraphSeparatorGlyphRange, atProposedOrigin: lineOrigin)
//        print("ze rect: ", lineFragmentUsedRect.pointee.height, " vs ", lineFragmentRect.pointee.height)
    }
    
    override func getLineFragmentRect(_ lineFragmentRect: NSRectPointer!, usedRect lineFragmentUsedRect: NSRectPointer!, remaining remainingRect: NSRectPointer!, forStartingGlyphAt startingGlyphIndex: Int, proposedRect: NSRect, lineSpacing: CGFloat, paragraphSpacingBefore: CGFloat, paragraphSpacingAfter: CGFloat) {
        super.getLineFragmentRect(lineFragmentRect, usedRect: lineFragmentUsedRect, remaining: remainingRect, forStartingGlyphAt: startingGlyphIndex, proposedRect: proposedRect, lineSpacing: lineSpacing, paragraphSpacingBefore: paragraphSpacingBefore, paragraphSpacingAfter: paragraphSpacingAfter)
//        print("getLineFragmentRect ", lineFragmentUsedRect?.pointee.height ?? -1, " vs ", lineFragmentRect?.pointee.height ?? -1, " and ", proposedRect.height)
        // This method is called twice for each change. The stack trace is the same, it seems.
        // In the first pass, the pointer is nil, and the rect's height really is 23.0 for lineFragmentRect and proposedRect.
        // In the second pass, lineFragmentRect is 33.58013916015625. That's the 10px paragraphSpacing.
        // We want to round in these "final" cases, after the default NSATSTypesetter implementation applied paragraph spacing for us.
        guard let lineFragmentUsedRect = lineFragmentUsedRect else {
            return
        }
        lineFragmentUsedRect.pointee.size.height = ceil(lineFragmentUsedRect.pointee.size.height)
        lineFragmentRect.pointee.size.height = ceil(lineFragmentRect.pointee.size.height)
    }
    
    override func paragraphSpacing(afterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: NSRect) -> CGFloat {
        let value = super.paragraphSpacing(afterGlyphAt: glyphIndex, withProposedLineFragmentRect: rect)
//        print("paraSpacingAfter", value, " for ", rect.height)
        return value
    }
    
    override func paragraphSpacing(beforeGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: NSRect) -> CGFloat {
        let value = super.paragraphSpacing(beforeGlyphAt: glyphIndex, withProposedLineFragmentRect: rect)
//        print("paraSpacingBefore", value, " for ", rect.height)
        return value
    }
}
