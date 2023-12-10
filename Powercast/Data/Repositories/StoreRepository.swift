import Foundation
import StoreKit

typealias Transaction = StoreKit.Transaction

class StoreRepository {
    private enum Item: String, CaseIterable {
        case additionalNotification = "notification.additional"
    }

    private(set) var notification: Product!

    private var updatingTask: Task<Void, Never>!

    private var purchasedProducts: [Product] = []

    init() {
        updatingTask = Task.detached { [updateProducts] in
            for await result in Transaction.updates {
                if case let VerificationResult.verified(transaction) = result {
                    await updateProducts()
                    await transaction.finish()
                }
            }
        }
    }

    deinit {
        updatingTask.cancel()
    }

    func load() async throws {
        let ids = Item.allCases.map { $0.rawValue }
        let products = try await Product.products(for: ids)
        notification = products.filter { $0.id == Item.additionalNotification.rawValue && $0.type == .nonConsumable }.first!
        await updateProducts()
    }

    func `is`(purchased: Product) -> Bool {
        purchasedProducts.contains(purchased)
    }

    func purchase(product: Product) async {
        guard let result = try? await product.purchase() else { return }
        if case let Product.PurchaseResult.success(verification) = result {
            if case let VerificationResult.verified(transaction) = verification {
                await updateProducts()
                await transaction.finish()
            }
        }
    }

    private func updateProducts() async {
        var purchasedProducts: [Product] = []
        for await result in Transaction.currentEntitlements {
            if case let VerificationResult.verified(transaction) = result, transaction.productID == notification.id {
                purchasedProducts.append(notification)
            }
        }
        self.purchasedProducts = purchasedProducts
    }
}