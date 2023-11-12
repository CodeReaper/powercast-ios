import Foundation

protocol Observer: AnyObject {
    func updated()
}

class Observerable {
    private var observers: [Observer] = []

    func add(observer: Observer) {
        observers.append(observer)
    }

    func remove(observer: Observer) {
        observers.removeAll(where: { $0 === observer })
    }

    func notifyObservers() {
        for observer in observers {
            Task {
                observer.updated()
            }
        }
    }
}
