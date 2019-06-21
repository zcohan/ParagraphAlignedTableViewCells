//
//  IndexedString.swift
//  SoulverKit
//
//  Created by Zac Cohan on 15/10/18.
//  Copyright © 2018 Zac Cohan. All rights reserved.
//

import Foundation


public class IndexedString: CustomDebugStringConvertible {

    public enum LineIndexGranularity {
        case Line
        case LineContents //no newline character
    }
    
    let granularity: LineIndexGranularity

    public let contents: String
    
    let cache: LineCache
    
    public init(contents: String, granularity: LineIndexGranularity) {
        
        self.contents = contents
        self.granularity = granularity
        self.cache = LineCache()
        
        self.loadMetrics()
    }
    
    
    public func removingLinesAt(indexes: IndexSet) -> IndexedString {
        
        let LineGranularityIndexedString = IndexedString(contents: self.contents, granularity: .LineContents)
        
        var string = ""
        
        LineGranularityIndexedString.enumerateLines { (lineIndex, line) in
            
            guard indexes.contains(lineIndex) == false else {
                return
            }
            
            if string.isNotEmpty {
                string.append(String.newlineSymbol)
            }

            string.append(line)
        }
        
        return IndexedString(contents: string, granularity: self.granularity)
    }
    
    func enumerateLines(invoking body: @escaping (Int, String) -> Void) {

        for lineIndex in 0..<self.cache.count() {
            
            let lineContents = self[lineIndex]            
            body(lineIndex, lineContents)
        }
        
    }
    
    // MARK: -  Public UI
    public func range() -> NSRange {
        return NSRange(location: 0, length: contents.count)
    }
    
    public func rangeOfLineContainingLocation(_ location: Int) -> NSRange {
        
        return (contents as NSString).lineRange(for: NSMakeRange(location, 0))
    }
    
    public func contentsRangeOfLineAtIndex(_ index: Int) -> NSRange {
        
        return self.cache.getAtIndex(index).contentsRange
    }
    
    public func rangeOfLineAtIndex(_ index: Int) -> NSRange {
        
        return self.cache.getAtIndex(index).range
    }

    public func isNewlineAt(_ index: Int) -> Bool {
        
        let line = self.cache.getAtIndex(index)
        return line.contents.isEmpty
    }
    
    public func substringFor(range: NSRange) -> String {
        return (self.contents as NSString).substring(with: range)
    }
    
    public func lineIndexesContainingRange(_ range: NSRange) -> ClosedRange<Int> {
        
        if (self.cache.lines.isEmpty) {
            return 0...0
        }
        let firstRange = rangeOfLineContainingLocation(range.lowerBound)
        
        // Handle the case where we've specified an entire line range
        if firstRange == range {
            let line = self.cache.getAtLocation(firstRange.lowerBound)
            
            //the case of |123\n| is technically both line 0 and line 1
            
            if line.index != self.countOfLines() - 1 {
                
                let nextLine = self.cache.getAtIndex(line.index + 1)
                if NSIntersectionRange(range, nextLine.range).length == nextLine.range.length {
                    return line.index ... nextLine.index
                }
                
            }
            
            return line.index ... line.index
            
        }
        
        let lastRange = range.length > 0
            ? rangeOfLineContainingLocation(range.upperBound)
            : firstRange
        let firstLine = self.cache.getAtLocation(firstRange.location)
        let lastLine = self.cache.getAtLocation(lastRange.location)
        
        
        return firstLine.index...lastLine.index
        
    }
    
    public func indexOfLineContainingLocation(_ location: Int) -> Int {
        
        if (self.cache.lines.isEmpty) {
            return 0
        }
        let range = rangeOfLineContainingLocation(location)
        let line = self.cache.getAtLocation(range.location)
        return line.index
    }
    
    public func countOfLines() -> Int {
        return self.cache.lines.count
    }

    public subscript(index: Int) -> String {
        get {
            let line = self.cache.getAtIndex(index)
            let range = self.granularity == .LineContents ? line.contentsRange : line.range
            return (self.contents as NSString).substring(with: range)
        }
    }
    
    
    // MARK: -  Loading
    
    private func loadMetrics() {
        
        let string = self.contents as NSString
        
        var location: Int = 0
        var lastContentsEnd: Int?
        var index: Int = 0
        let max = string.length
        while (location < max) {
            var lineStart: Int = 0
            var lineEnd: Int = 0
            var contentsEnd: Int = 0
            string.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd,
                                for: NSMakeRange(location, 0))
            let r = NSMakeRange(lineStart, lineEnd - lineStart)
            let contents = string.substring(with: r)

            let line = LineCache.Line(index: index, range: r,
                                                 contentsRange: NSMakeRange(lineStart, contentsEnd - lineStart), contents: contents)
            
            
            cache.addLine(line)
            index += 1
            location = NSMaxRange(r)
            lastContentsEnd = contentsEnd
        }
        if (lastContentsEnd == nil || lastContentsEnd != location) {
            // Last line ended with an end of line character, add another empty line to represent this
            let r = NSMakeRange(location, 0)
            let line = LineCache.Line(index: index, range: r, contentsRange: r, contents: "")
            cache.addLine(line)
        }
    }
    
    
    public var debugDescription: String {
        
        var description = "\(type(of: self)) (\(Unmanaged.passUnretained(self).toOpaque())))\n"
        description += "'\(self.contents)'"
                
        return description
        
    }

}


class LineCache {
    
    class Line {
        var index: Int
        /** Range of the entire line, including end of line character */
        var range: NSRange
        /** Range of line contents, not including end of line character */
        var contentsRange: NSRange
        
        var contents: String //includes new line
        
        init(index: Int, range: NSRange, contentsRange: NSRange, contents: String) {
            self.index = index
            self.range = range
            self.contentsRange = contentsRange
            self.contents = contents
        }
        
        
        var contentsWithoutNewLine: String {
            return (self.contents as NSString).substring(with: NSMakeRange(0, self.contentsRange.length))
        }
        
    }
    
    /** Lines keyed by range location */
    var linesByLocation: [Int: Line] = Dictionary()
    /** Lines by index */
    var lines: [Line] = Array()
    
    func getAtIndex(_ index: Int) -> Line {
        
        if index < self.lines.count {
            return lines[index]
        }
        
        print ("error")
        return Line(index: 0, range: NSMakeRange(0, 0), contentsRange: NSMakeRange(0, 0), contents: "")
        
        
    }
    
    func getAtLocation(_ location: Int) -> Line {
        return linesByLocation[location]!
    }
    
    func count() -> Int {
        return lines.count
    }
    
    func isEmpty() -> Bool {
        return lines.isEmpty
    }
    
    func invalidate() {
        linesByLocation.removeAll(keepingCapacity: true)
        lines.removeAll(keepingCapacity: true)
    }
    
    func addLine(_ line: Line) {
        lines.append(line)
        linesByLocation[line.range.location] = line
    }
    

    
}


public extension String {
    
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
    
    static var newlineSymbol: String {
        return "\n"
    }
    
}
