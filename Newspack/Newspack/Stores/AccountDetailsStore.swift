import Foundation
import CoreData
import WordPressFlux

/// Responsible for managing site related things.
///
class AccountDetailsStore: Store {

    /// Action handler
    ///
    override func onDispatch(_ action: Action) {

        if let apiAction = action as? AccountFetchedApiAction {
            handleAccountFetched(action: apiAction)
        }

    }

}

extension AccountDetailsStore {

    /// Handles the accountFetched action.
    ///
    /// - Parameters:
    ///     - user: The remote user
    ///     - error: Any error.
    ///
    func handleAccountFetched(action: AccountFetchedApiAction) {
        guard let user = action.payload else {
            if let _ = action.error {
                // TODO: Handle error
            }
            return
        }

        // TODO: This is tightly coupled to the current account
        // Need to find a way to inject the account.
        let accountStore = StoreContainer.shared.accountStore
        guard let account = accountStore.getAccountByUUID(action.accountUUID) else {
                return
        }

        let context = CoreDataManager.shared.mainContext
        let details = account.details ?? AccountDetails(context: context)

        details.userID = user.id
        details.name = user.name
        details.firstName = user.firstName
        details.lastName = user.lastName
        details.nickname = user.nickname
        details.email = user.email
        details.avatarUrls = user.avatarUrls
        details.link = user.link
        details.locale = user.locale
        details.slug = user.slug
        details.summary = user.description
        details.url = user.url
        details.username = user.username
        details.registeredDate = user.registeredDate

        account.details = details

        CoreDataManager.shared.saveContext()

        emitChange()
    }

}
