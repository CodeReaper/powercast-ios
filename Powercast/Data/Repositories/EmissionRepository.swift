import Foundation

class EmissionRepository {
    let co2: EmissionCo2Repository

    init(database: EmissionDatabase, service: EmissionService) {
        co2 = EmissionCo2Repository(database: database.queue, service: service)
    }
}
