//
//  ViewController.swift
//  ParagraphAlignedTableViewCells
//

import Cocoa


class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var tableView: NSTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.layoutManager?.typesetter = TietzeTypesetter()
        self.textView.textContainerInset = NSMakeSize(5.0, 0.0)
        self.tableView.intercellSpacing = NSMakeSize(0, 0)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = self.paragraphSpacing
        textView.textStorage?.addAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: NSMakeRange(0, (textView.textStorage!.string as NSString).length))
    }
    
    
    // MARK: -  Table View Delegate & Datasource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return IndexedString(contents: self.textView.string, granularity: .LineContents).countOfLines()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        
        guard let textField = view.textField else {
            return nil
        }
        
        textField.stringValue = self.textOfLineAt(lineIndex: row)
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return self.heightOfLineAtIndex(lineIndex: row)
    }
    
    // MARK: -  Styling
    
    var paragraphSpacing: CGFloat {
        return 10.0
    }
    
    // MARK: - String Metrics
    
    func rangeOfLineAt(lineIndex: Int) -> NSRange {
        
        return IndexedString(contents: self.textView.string, granularity: .LineContents).rangeOfLineAtIndex(lineIndex)
    }
    
    func textOfLineAt(lineIndex: Int) -> String {
        
        return IndexedString(contents: self.textView.string, granularity: .LineContents).contents
    }
    
    
    func heightOfLineAtIndex(lineIndex: Int) -> CGFloat {
        
        let paragraphRange = self.rangeOfLineAt(lineIndex: lineIndex)
        
        guard let layoutManager = self.textView.layoutManager, let textContainer = self.textView.textContainer else {
            return 0.0
        }
        
        let gRange = layoutManager.glyphRange(forCharacterRange: paragraphRange, actualCharacterRange: nil)
        
        let bounds = layoutManager.boundingRect(forGlyphRange: gRange, in: textContainer)
        
        return bounds.height + self.paragraphSpacing
        
    }
    
    
}

