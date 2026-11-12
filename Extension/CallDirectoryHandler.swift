import CallKit
import Foundation

final class CallDirectoryHandler: CXCallDirectoryProvider, CXCallDirectoryExtensionContextDelegate {
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        do {
            let ranges = try RuleEngine.ranges(for: SharedStorage.read())
            if context.isIncremental { context.removeAllBlockingEntries() }
            // Stream ascending, disjoint ranges; never allocate a million-number array.
            for range in ranges {
                for number in range.lower...range.upper {
                    context.addBlockingEntry(withNextSequentialPhoneNumber: number)
                }
            }
            context.completeRequest()
        } catch { context.cancelRequest(withError: error) }
    }

    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        NSLog("ChanDauSo: Call Directory failed: %@", error.localizedDescription)
    }
}
