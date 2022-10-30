import Foundation
import UIKit
import os

struct Humio {
    private struct Configuration {
        let configured: Bool
        let enabled: Bool
        let printMessages: Bool
        let token: String
        let storage: URL
        let endpoint: URL
        let allowsCellularAccess: Bool
        let frequencyTrigger: TimeInterval
        let amountTrigger: Int
        let additionalTags: [String: String]
    }

    static func setup(enabled: Bool = true, enabledPrintMessages: Bool = true, allowsCellularAccess: Bool = true, frequencyTrigger: TimeInterval = 60, amountTrigger: Int = 50, additionalTags: [String: String] = [:]) {
        guard !configuration.configured else { fatalError("Calling setup(...) multiple times is not supported.") }
        guard let token = Bundle.main.infoDictionary?["HUMIO_INGEST_TOKEN"] as? String else { fatalError("Did not find required 'HUMIO_INGEST_TOKEN' key in info.plist") }
        guard let space = Bundle.main.infoDictionary?["HUMIO_DATA_SPACE"] as? String else { fatalError("Did not find required 'HUMIO_DATA_SPACE' key in info.plist") }
        guard let endpoint = URL(string: "https://cloud.humio.com/api/v1/dataspaces/\(space)/ingest") else { fatalError("Unable to construct a valid URL with configured data space value: '\(space)'") }

        let storage = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

        configuration = Configuration(
            configured: true,
            enabled: enabled,
            printMessages: enabledPrintMessages,
            token: token,
            storage: storage,
            endpoint: endpoint,
            allowsCellularAccess: allowsCellularAccess,
            frequencyTrigger: max(5, frequencyTrigger),
            amountTrigger: min(100, max(10, amountTrigger)),
            additionalTags: additionalTags
        )

        guard configuration.enabled else { return }

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
            Self.flush()
        }

        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: Self.configuration.frequencyTrigger, repeats: true) { _ in
                Self.flush()
            }
        }
    }

    private static var configuration = Configuration(
        configured: false,
        enabled: false,
        printMessages: false,
        token: "N/A",
        storage: URL(fileURLWithPath: "/"),
        endpoint: URL(fileURLWithPath: "/"),
        allowsCellularAccess: false,
        frequencyTrigger: 0,
        amountTrigger: 0,
        additionalTags: [:]
    )
}

extension Humio {
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        queue(severity: "info", message, file, line)
    }

    static func info(_ message: String, file: String = #file, line: Int = #line) {
        queue(severity: "info", message, file, line)
    }

    static func warn(_ message: String, file: String = #file, line: Int = #line) {
        queue(severity: "warn", message, file, line)
    }

    static func error(_ message: String, file: String = #file, line: Int = #line) {
        queue(severity: "error", message, file, line)
    }
}

private extension Humio {
    private static var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Humio")
}

private extension Humio {
    private static var cache = [[String: Any]]()
    private static var cacheQueue = DispatchQueue(label: "Humio.cache.queue")

    private static func queue(severity: String, _ message: String, _ file: String, _ line: Int) {
        guard configuration.configured else { fatalError("A logging statement was attempted before setup(...) was called.") }
        guard configuration.enabled else { return }

        let event: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970 * 1000,
            "attributes": [
                "filename": URL(fileURLWithPath: file).lastPathComponent,
                "line": line,
                "level": severity
            ],
            "rawstring": message
        ]

        cacheQueue.async {
            self.cache.append(event)
            if self.cache.count >= self.configuration.amountTrigger {
                self.flush()
            }
        }

        guard configuration.printMessages else { return }

        print("Humio: \(message)")
    }

    private static func flush() {
        cacheQueue.async {
            let cache = self.cache
            self.cache = []
            send(events: cache)
        }
    }
}

private extension Humio {
    private static func send(events: [[String: Any]]) {
        guard events.count > 0 else { return }

        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")

        let preparedEvents = [[
            "tags": tags,
            "events": events
        ]]

        let filename = "\(UUID().uuidString).humio"
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: preparedEvents, options: [])
        } catch {
            logger.error("Found error: \(error, privacy: .private) while serializing given events: \(preparedEvents, privacy: .private)")
            return
        }
        do {
            try data.write(to: configuration.storage.appendingPathComponent(filename))
        } catch {
            logger.error("Found error: \(error, privacy: .private) while persisting events")
            return
        }

        let task = session.uploadTask(with: request, from: data)
        task.taskDescription = filename
        task.resume()
    }

    private static var session = {
        var configuration = URLSessionConfiguration.ephemeral
        configuration.allowsCellularAccess = Self.configuration.allowsCellularAccess
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: .main)
    }()

    private static var delegate = Delegate()

    private class Delegate: NSObject, URLSessionDataDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? -1
            let filename = task.taskDescription ?? "not-found"
            let file = configuration.storage.appendingPathComponent(filename)

            switch statusCode {
            case 200..<300, 400..<500:
                try? FileManager.default.removeItem(at: file)
            default:
                guard
                    let data = try? Data(contentsOf: file, options: []),
                    let request = task.originalRequest
                else {
                    try? FileManager.default.removeItem(at: file)
                    logger.warning("Unable to attempt retry for \(filename), statusCode was \(statusCode)")
                    return
                }
                let nextTask = session.uploadTask(with: request, from: data)
                nextTask.taskDescription = task.taskDescription
                nextTask.resume()
            }
        }
    }
}

private extension Humio {
    private static var tags: [String: Codable] = {
        let version = ProcessInfo().operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        var sysinfo = utsname()
        uname(&sysinfo)
        let deviceIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)

        return [
            "platform": "ios",
            "bundleIdentifier": Bundle.main.bundleIdentifier!,
            "CFBundleVersion": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "CFBundleShortVersionString": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "systemVersion": versionString,
            "deviceModel": deviceIdentifier
        ]
    }()
}
