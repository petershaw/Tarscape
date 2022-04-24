import XCTest
@testable import Tarscape

final class TarscapeTests: XCTestCase {
    
    func testSimpleRoundTrip() throws {
        
        // Create some files, archive them, extract them, and check that what we
        // got out matches what we put in.
        let fm = FileManager.default
        let tempFolder = fm.temporaryDirectory.appendingPathComponent("tarscape_tests")
        try fm.createDirectory(at: tempFolder, withIntermediateDirectories: false, attributes: nil)
        
        defer {
            // Clean up.
            try? fm.removeItem(at: tempFolder)
        }
        
        let dirURL = tempFolder.appendingPathComponent("archive_folder")
        try fm.createDirectory(at: dirURL, withIntermediateDirectories: false, attributes: nil)
        
        try "Hello world".write(to: dirURL.appendingPathComponent("file1.txt"), atomically: true, encoding: .utf8)
        let innerFolder = dirURL.appendingPathComponent("inner_folder")
        try fm.createDirectory(at: innerFolder, withIntermediateDirectories: false, attributes: nil)
        #if os(Linux)
        let file2Date = Date(timeIntervalSinceNow: 0) //-(3 * 24 * 60 * 60) // ToDo: Linux can not set modificationDate
        #else
        let file2Date = Date(timeIntervalSinceNow: -(3 * 24 * 60 * 60))
        #endif
        let file2URL = innerFolder.appendingPathComponent("file2.txt")
        try "Another file".write(to: file2URL, atomically: true, encoding: .utf8)
        try fm.setAttributes([.modificationDate: file2Date], ofItemAtPath: file2URL.path)
        try Data().write(to: dirURL.appendingPathComponent("empty_file"))
        
        // Archive the folder.
        let tarURL = tempFolder.appendingPathComponent("archive.tar")
        try fm.createTar(at: tarURL, from: dirURL)
        
        // And unarchive.
        let untarURL = tempFolder.appendingPathComponent("unarchived")
        try fm.extractTar(at: tarURL, to: untarURL)
        
        // Check things match.
        XCTAssert(fm.fileExists(atPath: untarURL.appendingPathComponent("file1.txt").path), "file1 does not exists.")
        let f1text = try String(contentsOf: untarURL.appendingPathComponent("file1.txt"), encoding: .utf8)
        XCTAssert(f1text == "Hello world", "File1 content is not the same")
        var isDir:ObjCBool = false
        let untarInnerFolder =  untarURL.appendingPathComponent("inner_folder")
        XCTAssert(fm.fileExists(atPath: untarInnerFolder.path, isDirectory: &isDir) && isDir.boolValue, "Inner folder does not exists.")
        let untarFile2URL = untarInnerFolder.appendingPathComponent("file2.txt")
        XCTAssert(fm.fileExists(atPath: untarFile2URL.path), "File2 dies not exist.")
        let f2text = try String(contentsOf: untarFile2URL, encoding: .utf8)
        XCTAssert(f2text == "Another file", "File2 content is not the same")
        XCTAssert(fm.fileExists(atPath: untarURL.appendingPathComponent("empty_file").path), "Empty file does not exist.")
        
        if let emptyLen = try fm.attributesOfItem(atPath: untarURL.appendingPathComponent("empty_file").path)[.size] as? Int {
            XCTAssert(emptyLen == 0, "Empty file size is not zero.")
        }
        
        // Check dates match.
        let untarFile2Date = try fm.attributesOfItem(atPath: untarFile2URL.path)[.modificationDate] as? Date
        XCTAssert(untarFile2Date != nil, "Modification date is nil.")
        
        // Dates should match down to seconds, but not at any finer granularity, so use date components
        // for comparison becuase Date1 == Date2 is likely to fail.
        if let untarFile2Date = untarFile2Date {
            let dateComps1 = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: file2Date)
            let dateComps2 = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: untarFile2Date)
            XCTAssertEqual(dateComps1.day!, dateComps2.day!, "Day is not the same.")
            XCTAssertEqual(dateComps1.month!, dateComps2.month!, "Month is not the same.")
            XCTAssertEqual(dateComps1.year!, dateComps2.year!, "Year is not the same.")
            XCTAssertEqual(dateComps1.hour!, dateComps2.hour!, "Hour is not the same.")
            XCTAssertEqual(dateComps1.minute!, dateComps2.minute!, "Minute is not the same.")
            XCTAssertEqual(dateComps1.second!, dateComps2.second!, "Second is not the same.")
        }
    }
    
    func testEntry() throws {
        
        // Create some files, archive them, extract them, and check that what we
        // got out matches what we put in.
        let fm = FileManager.default
        let tempFolder = fm.temporaryDirectory.appendingPathComponent("tarscape_tests")
        try fm.createDirectory(at: tempFolder, withIntermediateDirectories: false, attributes: nil)
        
        defer {
            // Clean up.
            try? fm.removeItem(at: tempFolder)
        }
        
        // Create:
        // archive_folder
        //   file1.txt
        //   holder_folder
        //     test_folder // has 5 descendants.
        //        test1.txt
        //        inner1
        //          inner.txt
        //          inner2
        //            deeper.txt
        
        let dirURL = tempFolder.appendingPathComponent("archive_folder")
        try fm.createDirectory(at: dirURL, withIntermediateDirectories: false, attributes: nil)
        
        try "Hello world".write(to: dirURL.appendingPathComponent("file1.txt"), atomically: true, encoding: .utf8)
        
        let holderFolder = dirURL.appendingPathComponent("holder_folder")
        try fm.createDirectory(at: holderFolder, withIntermediateDirectories: false, attributes: nil)
        
        let testFolder = holderFolder.appendingPathComponent("test_folder")
        try fm.createDirectory(at: testFolder, withIntermediateDirectories: false, attributes: nil)
        
        try "Hello again world".write(to: testFolder.appendingPathComponent("test1.txt"), atomically: true, encoding: .utf8)
        
        let innnerFolder = testFolder.appendingPathComponent("inner1")
        try fm.createDirectory(at: innnerFolder, withIntermediateDirectories: false, attributes: nil)
        try "Inner text".write(to: innnerFolder.appendingPathComponent("inner.txt"), atomically: true, encoding: .utf8)
        
        let deeperFolder = innnerFolder.appendingPathComponent("inner2")
        try fm.createDirectory(at: deeperFolder, withIntermediateDirectories: false, attributes: nil)
        try "Deeper text".write(to: deeperFolder.appendingPathComponent("deeper.txt"), atomically: true, encoding: .utf8)
        
        // Create the archive.
        
        // Archive the folder.
        let tarURL = tempFolder.appendingPathComponent("archive.tar")
        try fm.createTar(at: tarURL, from: dirURL)
        
        let unarchiver = try KBTarUnarchiver(tarURL: tarURL)
        //try unarchiver.loadAllEntries(lazily: true)
        let testFolderEntry = unarchiver["holder_folder/test_folder"]
        XCTAssert(testFolderEntry != nil)
        if let testFolderEntry = testFolderEntry {
            XCTAssert(testFolderEntry.descendants.count == 5)
            
            //var string = ""
            //buildEntryText(&string, entry: testFolderEntry, depth: 0)
            //try string.write(to: fm.temporaryDirectory.appendingPathComponent("entry_info.txt"), atomically: true, encoding: .utf8)
            
            let entryFolder = fm.temporaryDirectory.appendingPathComponent("written_entry")
            try testFolderEntry.write(to: entryFolder, atomically: true)
            
            defer {
                try? fm.removeItem(at: entryFolder)
            }
            
            let expectedSubpaths = ["test1.txt", "inner1", "inner1/inner.txt", "inner1/inner2", "inner1/inner2/deeper.txt"]
            var str = ""
            for subpath in expectedSubpaths {
                let expectedURL = entryFolder.appendingPathComponent(subpath)
                str += expectedURL.path + "\n"
                XCTAssert(fm.fileExists(atPath: expectedURL.path), "expected path not found: \(expectedURL.path)")
            }
        }
    }
    
    // Grab a list of descendants - useful for debugging.
    func buildEntryText(_ string: inout String, entry: KBTarEntry, depth: Int) {
        string += String(repeating: "  ", count: depth) + entry.name + "\n"
        for childEntry in entry.children {
            buildEntryText(&string, entry: childEntry, depth: depth+1)
        }
    }
}
