import Foundation
import Flogger

protocol ConfigurationService {
    func configuration() async throws -> Configuration
}

class ConfigurationServiceAPI: ConfigurationService {
    func configuration() async throws -> Configuration {
        let url = URL(string: "\(endpoint)/requirements/")!
        let data = try await fetch(url: url)
        let requirements = try decoder.decode(Requirements.self, from: data)
        return Configuration(minimumBuildVersion: requirements.minimumBuild)
    }

    private let endpoint = "https://codereaper.github.io/powercast-data/api"
    private let decoder = JSONDecoder()
    private let session = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        return URLSession(configuration: configuration)
    }()
    private func fetch(url: URL) async throws -> Data {
        let (data, base) = try await session.data(from: url)
        let response = base as! HTTPURLResponse // swiftlint:disable:this force_cast

        Flog.info("GET \(url) \(response.statusCode) \(data.count)")

        return data
    }
}

private struct Requirements: Codable {
    let minimumBuild: Int
}
