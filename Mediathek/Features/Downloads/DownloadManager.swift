//
//  DownloadManager.swift
//  Mediathek
//
//  Created by Jon on 03.06.25.
//

import Foundation
import Combine
#if os(macOS)
import AppKit
#endif

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var downloads: [DownloadItem] = []

    private var session: URLSession!
    private var downloadItemMap: [URLSessionDownloadTask: DownloadItem] = [:]
    private var startTimes: [URLSessionDownloadTask: Date] = [:]
    private var lastUpdateTimes: [URLSessionDownloadTask: Date] = [:]

    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.waitsForConnectivity = false
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - Public Methods

    func startDownload(from url: URL, title: String, thumbnailURL: URL? = nil) {
        // 1. Check if a similar active/pending download already exists
        if downloads.contains(where: { existingItem in
            return existingItem.url == url &&
                   (existingItem.status == .downloading || existingItem.status == .paused || existingItem.status == .pending)
        }) {
            print("Download for \(url) is already in progress, paused, or pending. Skipping.")
            return
        }
        
        // 2. Create the DownloadItem
        let item = DownloadItem(url: url, title: title, thumbnailURL: thumbnailURL)
        
        // 3. Create the URLSessionDownloadTask
        let task = session.downloadTask(with: url)
        
        // 4. IMPORTANT: Link the task to the item and map BEFORE task.resume()
        item.task = task
        downloadItemMap[task] = item // Populate map immediately
        
        // 5. Update item status and add to published array on main queue
        DispatchQueue.main.async {
            item.status = .downloading // Set initial status to downloading as it's about to start
            //self.downloads.insert(item, at: 0) // Add new downloads at the top
            self.downloads.append(item)
            self.startTimes[task] = Date() // Record start time here
        }
        
        // 6. Resume the task
        task.resume()
    }

    func pauseDownload(_ item: DownloadItem) {
        guard item.status == .downloading, let task = item.task else { return }

        task.cancel(byProducingResumeData: { [weak self] data in
            DispatchQueue.main.async {
                item.resumeData = data
                item.status = .paused
                item.task = nil // Dereference the task
                item.estimatedTimeRemaining = nil // Clear ETA when paused
                self?.cleanupTask(task) // Clean up maps
            }
        })
    }

    func resumeDownload(_ item: DownloadItem) {
        guard item.status == .paused, let resumeData = item.resumeData else { return }

        let task = session.downloadTask(withResumeData: resumeData)
        item.task = task
        item.status = .downloading
        item.resumeData = nil // Clear resume data once used

        downloadItemMap[task] = item
        startTimes[task] = Date() // Reset start time for accurate ETA

        task.resume()
    }

    func cancelDownload(_ item: DownloadItem) {
        item.task?.cancel()
        DispatchQueue.main.async {
            item.status = .canceled
            item.task = nil // Dereference the task
            item.estimatedTimeRemaining = nil // Clear ETA when cancelled
            item.errorMessage = nil // Clear any error message
        }
        // Cleanup will happen in didCompleteWithError for cancelled tasks
    }
    
    // MARK: - Reveal File Method
    func revealFile(for item: DownloadItem) {
        #if os(macOS)
        guard item.status == .completed, let url = item.destinationURL else {
            print("Cannot reveal file. Download not completed or destination URL not set for item: \(item.title)")
            return
        }

        // Check if the file actually exists at the URL
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            // Optionally, update item status to failed or provide an error message
            DispatchQueue.main.async {
                item.status = .failed
                item.errorMessage = "File not found at destination."
            }
            return
        }
        
        // Use NSWorkspace to reveal the item
        NSWorkspace.shared.activateFileViewerSelecting([url])
        print("Revealed file: \(url.lastPathComponent) in Finder.")
        #else
        print("Reveal file functionality is only available on macOS.")
        // For iOS, you might want to implement QuickLook or sharing options
        #endif
    }
    
    // MARK: - Open File Method
    func openFile(for item: DownloadItem) {
        #if os(macOS)
        guard item.status == .completed, let url = item.destinationURL else {
            print("Cannot open file. Download not completed or destination URL not set for item: \(item.title)")
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            DispatchQueue.main.async {
                item.status = .failed
                item.errorMessage = "File not found at destination."
            }
            return
        }

        let success = NSWorkspace.shared.open(url)
        if success {
            print("Opened file: \(url.lastPathComponent)")
        } else {
            print("Failed to open file: \(url.lastPathComponent)")
            DispatchQueue.main.async {
                item.status = .failed
                item.errorMessage = "Failed to open file."
            }
        }
        #else
        print("Open file functionality is only available on macOS via default app association.")
        // For iOS, this would typically involve QuickLook or a sharing sheet.
        // For a more robust iOS "open," you might use UIDocumentInteractionController
        // or just rely on sharing to other apps.
        #endif
    }


    // Helper to clean up internal maps
    private func cleanupTask(_ task: URLSessionDownloadTask) {
        downloadItemMap[task] = nil
        startTimes[task] = nil
        lastUpdateTimes[task] = nil
    }
}


// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        guard let item = downloadItemMap[downloadTask] else { return }

        let now = Date()
        let lastUpdate = DownloadManager.shared.lastUpdateTimes[downloadTask] ?? .distantPast

        // Only update if at least 1 second has passed
        if now.timeIntervalSince(lastUpdate) >= 1.0 {
            DownloadManager.shared.lastUpdateTimes[downloadTask] = now
            
            // All UI updates must be on the main queue
            DispatchQueue.main.async {
                let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                item.progress = progress
                
                // Estimate remaining time
                if let startTime = self.startTimes[downloadTask] {
                    let elapsed = Date().timeIntervalSince(startTime)
                    // Calculate speed in bytes/second
                    let speed = Double(totalBytesWritten) / elapsed
                    
                    if speed > 0 {
                        let remainingBytes = Double(totalBytesExpectedToWrite - totalBytesWritten)
                        let estimatedTime = remainingBytes / speed
                        item.estimatedTimeRemaining = estimatedTime
                    } else {
                        item.estimatedTimeRemaining = nil // Can't estimate if no speed
                    }
                }
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {

        guard let item = downloadItemMap[downloadTask] else { return }

        // Determine a permanent filename
        let filename = downloadTask.response?.suggestedFilename ?? item.url.lastPathComponent
        // Use a more specific directory for downloads (e.g., Application Support if not user-facing, or Downloads if for user)
        // For simplicity, let's stick to .downloadsDirectory for now, but be aware of sandboxing.
        let downloadsFolderURL: URL
        #if os(iOS)
        // For iOS, usually documents directory or a custom subfolder is used
        downloadsFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #else // macOS
        downloadsFolderURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        #endif
        
        let destinationURL = downloadsFolderURL.appendingPathComponent(filename)

        // Remove existing file if any (important to prevent "file exists" errors)
        try? FileManager.default.removeItem(at: destinationURL)

        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("✅ File moved to: \(destinationURL.lastPathComponent)")
            DispatchQueue.main.async {
                item.destinationURL = destinationURL
                item.status = .completed
                item.task = nil
                item.estimatedTimeRemaining = nil
                item.errorMessage = nil // Clear any potential error
            }
        } catch {
            print("❌ Error moving file \(location.lastPathComponent) to \(destinationURL.lastPathComponent): \(error.localizedDescription)")
            DispatchQueue.main.async {
                item.status = .failed
                item.errorMessage = "Failed to save file: \(error.localizedDescription)"
            }
        }
        // Cleanup task references after completion or error in saving
        cleanupTask(downloadTask)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let item = downloadItemMap[downloadTask] else { return }

        DispatchQueue.main.async {
            if let error = error as NSError? {
                // NSURLErrorCancelled is expected when pausing/cancelling
                if error.code != NSURLErrorCancelled {
                    item.status = .failed
                    item.errorMessage = error.localizedDescription // Set the error message
                    print("❌ Download failed for \(item.title): \(error.localizedDescription)")
                } else {
                    // Task was cancelled by user (or paused), status is already set by pause/cancel methods
                    // No need to change status here, just cleanup
                    print("Download for \(item.title) cancelled.")
                }
            } else {
                // This block might be hit if a task completes without error but `didFinishDownloadingTo`
                // failed to move the file (e.g., permissions issue).
                // Ensure status is correctly reflected if it's not already .completed
                if item.status != .completed {
                    item.status = .failed
                    item.errorMessage = "Download completed but file could not be saved."
                }
            }
            item.task = nil // Dereference the task
            item.estimatedTimeRemaining = nil // Clear ETA on error/cancel
        }
        cleanupTask(downloadTask) // Always clean up after task completes (success or failure)
    }
}
