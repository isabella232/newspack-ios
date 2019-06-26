import XCTest
import CoreData
import WordPressFlux
@testable import Newspack

class SiteStoreTests: BaseTest {

    var store: SiteStore?
    var remoteSettings: RemoteSiteSettings?
    var account: Account?
    let siteURL = "http://example.com"

    override func setUp() {
        super.setUp()

        store = StoreContainer.shared.siteStore

        // Test account
        account = accountStore!.createAccount(authToken: "testToken", forNetworkAt: siteURL)
        accountStore!.currentAccount = account

        // Test settings
        let response = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        remoteSettings = RemoteSiteSettings(dict: response)
    }

    override func tearDown() {
        super.tearDown()

        store = nil
        account = nil
        remoteSettings = nil
    }

    func testCreateSite() {
        let account = self.account!
        let remoteSettings = self.remoteSettings!
        let dispatcher = ActionDispatcher.global

        let receipt = store?.onChange {}

        // Error when missing account
        let action = SiteFetchedApiAction(payload: remoteSettings, error: nil, accountUUID: account.uuid, siteUUID: nil)
        dispatcher.dispatch(action)

        let site = account.currentSite

        XCTAssertNotNil(receipt)
        XCTAssertNotNil(site)
        XCTAssertEqual(site!.url, siteURL)
        XCTAssertEqual(site!.title, remoteSettings.title)
    }

    func testUpdateSite() {
        let account = self.account!
        var remoteSettings = self.remoteSettings!
        let dispatcher = ActionDispatcher.global
        let testTitle = "Test Title"
        var site: Site?

        store?.createSite(url: siteURL, settings: remoteSettings, accountID: account.uuid)
        site = account.currentSite!

        XCTAssertNotNil(site)
        XCTAssertEqual(site!.title, remoteSettings.title)
        XCTAssertNotEqual(site!.title, testTitle)

        let receipt = store?.onChange {}

        var dict = Loader.jsonObject(for: "remote-site-settings") as! [String: AnyObject]
        dict["title"] = testTitle as AnyObject
        remoteSettings = RemoteSiteSettings(dict: dict)

        // Error when missing account
        let action = SiteFetchedApiAction(payload: remoteSettings, error: nil, accountUUID: account.uuid, siteUUID: site!.uuid)
        dispatcher.dispatch(action)

        XCTAssertNotNil(receipt)
        XCTAssertNotNil(site)
        XCTAssertEqual(site!.url, siteURL)
        XCTAssertEqual(site!.title, testTitle)
    }

    func testSingleAccountHasMultipleSites() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!

        let site1 = ModelFactory.getTestSite(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.account = account

        let site2 = ModelFactory.getTestSite(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.account = account

        CoreDataManager.shared.saveContext()

        XCTAssertEqual(account.sites.count, 2)
    }

    func testMultipleAccountsCannotShareSite() {
        let context = CoreDataManager.shared.mainContext

        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"

        let account2 = Account(context: context)
        account2.uuid = UUID()
        account2.networkUrl = "http://account2.com"

        let site = ModelFactory.getTestSite(context: context)
        site.account = account1

        CoreDataManager.shared.saveContext()

        XCTAssertNotNil(account1.currentSite)
        XCTAssertNil(account2.currentSite)

        site.account = account2
        CoreDataManager.shared.saveContext()

        XCTAssertNil(account1.currentSite)
        XCTAssertNotNil(account2.currentSite)
    }

    func testDefaultSiteAfterRemovingCurrentSite() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!

        let site1 = ModelFactory.getTestSite(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.account = account

        let site2 = ModelFactory.getTestSite(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.account = account

        CoreDataManager.shared.saveContext()
        XCTAssertEqual(account.sites.count, 2)

        var currentSite = account.currentSite!
        let title = currentSite.title
        context.delete(currentSite)
        CoreDataManager.shared.saveContext()

        XCTAssertEqual(account.sites.count, 1)
        currentSite = account.currentSite!
        XCTAssertNotNil(currentSite)
        XCTAssertNotEqual(title, currentSite.title)
    }

    func testRemovingAccountRemovesSites() {
        let context = CoreDataManager.shared.mainContext
        let account = self.account!

        let site1 = ModelFactory.getTestSite(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.account = account

        let site2 = ModelFactory.getTestSite(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.account = account

        CoreDataManager.shared.saveContext()

        let fetchRequest = Site.defaultFetchRequest()
        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 2)

        context.delete(account)
        CoreDataManager.shared.saveContext()

        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 0)
    }

    func testRemovingAccountDoesNotRemoveOtherAccountSites() {
        let context = CoreDataManager.shared.mainContext

        let account1 = Account(context: context)
        account1.uuid = UUID()
        account1.networkUrl = "http://account1.com"

        let site1 = ModelFactory.getTestSite(context: context)
        site1.url = "url1"
        site1.title = "site1"
        site1.account = account1

        let account2 = Account(context: context)
        account2.uuid = UUID()
        account2.networkUrl = "http://account2.com"

        let site2 = ModelFactory.getTestSite(context: context)
        site2.url = "url2"
        site2.title = "site2"
        site2.account = account2

        CoreDataManager.shared.saveContext()

        let fetchRequest = Site.defaultFetchRequest()
        var count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 2)

        context.delete(account1)
        CoreDataManager.shared.saveContext()

        count = try! context.count(for: fetchRequest)
        XCTAssertEqual(count, 1)
    }

    func testSingleAccountNoDuplicateSites() {
        // TODO.  This is going to be tricky.
    }
}
