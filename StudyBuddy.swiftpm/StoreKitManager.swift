import Foundation
import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var storeProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    // Hardcoded product IDs matching our storekit config
    let productDict: [Tier: String] = [
        .pro: "com.studybuddy.pro.monthly.v2",
        .max: "com.studybuddy.max.monthly"
    ]
    
    private var updatesTask: Task<Void, Never>? = nil
    
    private init() {
        updatesTask = listenForTransactions()
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    func fetchProducts() async {
        do {
            let ids = Array(productDict.values)
            print("[StoreKit] Fetching products for IDs: \(ids)")
            let products = try await Product.products(for: ids)
            print("[StoreKit] Fetched \(products.count) products: \(products.map { $0.id })")
            self.storeProducts = products.sorted(by: { $0.price < $1.price })
        } catch {
            print("[StoreKit] Failed to fetch products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateCustomerProductStatus()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func purchase(tier: Tier) async throws -> Transaction? {
        // Auto-fetch products if they haven't loaded yet
        if storeProducts.isEmpty {
            print("[StoreKit] Products empty, fetching before purchase...")
            await fetchProducts()
        }
        
        guard let productID = productDict[tier] else {
            throw NSError(domain: "StoreKitManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No product ID configured for tier: \(tier.rawValue)"])
        }
        
        guard let product = storeProducts.first(where: { $0.id == productID }) else {
            print("[StoreKit] Available products: \(storeProducts.map { $0.id })")
            print("[StoreKit] Looking for: \(productID)")
            throw NSError(domain: "StoreKitManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Product '\(productID)' not found. Found \(storeProducts.count) products. Make sure 'Products.storekit' is selected in Xcode Scheme → Run → Options → StoreKit Configuration."])
        }
        return try await purchase(product)
    }
    
    func updateCustomerProductStatus() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // If it's a subscription, check if it's active
                if transaction.productType == .autoRenewable {
                    guard let expirationDate = transaction.expirationDate else { continue }
                    if expirationDate > Date() {
                        purchased.insert(transaction.productID)
                    }
                } else {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchased
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateCustomerProductStatus()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
