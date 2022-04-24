//
//  FileManager+Tar.swift
//  FileManager+Tar
//
//  Created by Keith Blount on 20/09/2021.
//

import Foundation

public extension FileManager {

    /// Extracts the tar at `tarURL` to `dirURL`.
    /// - Parameter at: The path of the Tar file to extract.
    /// - Parameter to: The path to which to extract the Tar file. A directory will be created at this path containing the extracted files.
    /// - Parameter options: List of  KBTarUnarchiver.Options, default .restoreFileAttributes
    /// - Parameter progress: A closure with a `Double` parameter representing the current progress (from 0.0 to 1.0).
    func extractTar(at tarURL: URL, to dirURL: URL, options: KBTarUnarchiver.Options = [.restoreFileAttributes], progress: Progress? = nil) throws {
        let unarchiver = try KBTarUnarchiver(tarURL: tarURL, options: options)
        
        var progressBody: ((Double, Int64) -> Void)?
        
        if progress != nil {
            // Asking for the progress count enumerates through files in advance, so only
            // do this if we actually want to use the progress.
            progress?.totalUnitCount = unarchiver.progressCount
            progressBody = {(_, currentFileNum) in
                progress?.completedUnitCount = currentFileNum
            }
        }
        
        try KBTarUnarchiver(tarURL: tarURL, options: options).extract(to: dirURL, progressBody: progressBody)
    }


    /// Creates a Tar file at `tarURL`.
    /// - Parameter at: The path at which the Tar file should be created.
    /// - Parameter from: A directory containing the files that that should be archived.
    /// - Parameter options: List of KBTarArchiver.Options
    /// - Parameter progressBody: A closure with a `Double` parameter representing the current progress (from 0.0 to 1.0).
    func createTar(at tarURL: URL, from dirURL: URL, options: KBTarArchiver.Options = [],  progress: Progress? = nil) throws {
        let archiver = KBTarArchiver(directoryURL: dirURL, options: options)
        
        var progressBody: ((Double, Int64) -> Void)?
        
        if progress != nil {
            progress?.totalUnitCount = archiver.progressCount
            progressBody = {(_, currentFileNum) in
                progress?.completedUnitCount = currentFileNum
            }
        }
        
        try KBTarArchiver(directoryURL: dirURL, options: options).archive(to: tarURL, progressBody: progressBody)
    }
    
}
