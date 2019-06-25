import Foundation
import CoreData
import KeychainAccess
import WordPressFlux

/// Responsible for managing account and keychain related things.
///
class AccountStore: EventfulStore {
    private let currentAccountUUIDKey: String = "currentAccountUUIDKey"
    private static let keychainServiceName: String = "com.automattic.newspack"
    private let keychain: Keychain

    /// Initializer
    ///
    init(dispatcher: ActionDispatcher = .global, keychainServiceName: String = AccountStore.keychainServiceName) {
        self.keychain = Keychain(service: keychainServiceName).accessibility(.afterFirstUnlock)
        super.init(dispatcher: dispatcher)
    }

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {
        guard let accountAction = action as? AccountAction else {
            return
        }
        
        switch accountAction {
        case .setCurrentAccount(let account):
            setCurrentAccount(account: account)
            break
        case .setCurrentSite(let site, let account):
            setCurrentSite(site: site, for: account)
            break
        }
    }
}

extension AccountStore {

    /// Get or set the current account.
    ///
    var currentAccount: Account? {
        get {
            guard
                let uuidString = UserDefaults.standard.string(forKey: currentAccountUUIDKey),
                let uuid = UUID(uuidString: uuidString),
                let account = getAccountByUUID(uuid)
                else {
                    // Womp womp.
                    return nil
            }
            return account
        }
        set(account) {
            if account == currentAccount {
                return
            }

            let defaults = UserDefaults.standard

            defer {
                defaults.synchronize()
                emitChange()
            }

            guard let account = account else {
                defaults.removeObject(forKey: currentAccountUUIDKey)
                return
            }
            defaults.set(account.uuid.uuidString, forKey: currentAccountUUIDKey)
        }
    }

    /// Get the account for the specified UUID
    ///
    /// - Parameter uuid: The account's UUID
    /// - Returns: The account
    ///
    func getAccountByUUID(_ uuid: UUID) -> Account? {
        let fetchRequest = Account.defaultFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
        let context = CoreDataManager.shared.mainContext
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            // TODO: Need to log this
            let error = error as NSError
            print(error.localizedDescription)
        }
        return nil
    }

    /// Get all accounts
    ///
    /// - Returns: An array of Accounts. The array may be empty.
    ///
    func getAccounts() -> [Account] {
        let fetchRequest = Account.defaultFetchRequest()
        let context = CoreDataManager.shared.mainContext
        do {
            let accounts = try context.fetch(fetchRequest)
            return accounts
        } catch {
            // TODO: Need to log this
            let error = error as NSError
            print(error.localizedDescription)
        }
        return [Account]()
    }

    /// Get the number of accounts currently in the app.
    ///
    /// - Returns: The number of accounts.
    ///
    func numberOfAccounts() -> Int {
        let fetchRequest = Account.defaultFetchRequest()
        let context = CoreDataManager.shared.mainContext
        let count = (try? context.count(for: fetchRequest)) ?? 0
        return count
    }

}

extension AccountStore {

    /// Creates a new account with the specified username and auth token.
    /// The new account is made the current account.
    ///
    /// - Parameters:
    ///     - authToken: The REST API auth token for the account.
    ///
    @discardableResult
    func createAccount(authToken: String, forNetworkAt url: String) -> Account {
        let context = CoreDataManager.shared.mainContext
        let account = Account(context: context)
        account.uuid = UUID()
        account.networkUrl = url

        CoreDataManager.shared.saveContext()

        setAuthToken(authToken, for: account)

        return account
    }

    /// Handler for the .setCurrentAccount action.
    ///
    /// - Parameter account: The new account or nil.
    ///
    func setCurrentAccount(account: Account?) {
        // Note: The computed property will emit the event.
        currentAccount = account
    }

    /// Handler for the .setCurrentSite action.
    ///
    func setCurrentSite(site: Site, for account: Account) {
        guard account.sites.contains(site) else {
            return
        }
        guard site != account.currentSite else {
            return
        }

        account.currentSite = site

        emitChange()
    }
}


/// Auth token management
extension AccountStore {

    /// Get the auth token for the spedified account.
    ///
    /// - Parameter:
    ///   - account: The account.
    /// - Returns: The auth token.
    ///
    func getAuthTokenForAccount(_ account: Account) -> String? {
        return keychain[account.uuid.uuidString]
    }

    /// Store the specified auth token for the specified account.
    ///
    /// - Parameters:
    ///   - token: The auth token.
    ///   - account: The account.
    ///
    func setAuthToken(_ token: String, for account: Account) {
        keychain[account.uuid.uuidString] = token
    }

    /// Clear the auth token for the specified account.
    ///
    /// - Parameters:
    ///   - account: The account.
    ///
    func clearAuthTokenForAccount(_ account: Account) {
        keychain[account.uuid.uuidString] = nil
    }

    /// Clear all stored auth tokens.
    ///
    func clearAuthTokens() {
        try? keychain.removeAll()
    }
}
