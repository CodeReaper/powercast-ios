import Foundation

struct Configuration {
    let minimumBuildVersion: Int
}

extension Configuration {
    static var `default` = Configuration(minimumBuildVersion: 0)
}
