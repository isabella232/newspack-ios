import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var sessionReceipt: Any?
    var window: UIWindow?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Need to configure the user agent as early as possible.
        UserAgent.configure()
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure the window which should call makeKeyAndVisible.
        // Necessary in order to present the authentication flow.
        configureWindow()
        configureSession()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension AppDelegate {

    func configureWindow() {
        window?.makeKeyAndVisible()
    }

    func configureSession() {
        sessionReceipt = SessionManager.shared.onChange {
            self.handleSessionChange()
        }

        SessionManager.shared.initialize(account: StoreContainer.shared.accountStore.currentAccount)
    }

    func handleSessionChange() {
        guard let navController = window?.rootViewController as? UINavigationController else {
            return
        }
        defer {
            navController.popToRootViewController(animated: true)
        }
        if SessionManager.shared.state == .uninitialized {
            handleUnauthenticatedSession()
        }
    }

    func handleUnauthenticatedSession() {
        guard let navController = window?.rootViewController as? UINavigationController else {
            return
        }

        if navController.viewControllers.first is InitialViewController {
            return
        }

        let controller = MainStoryboard.instantiateViewController(withIdentifier: "InitialViewController")
        var controllers = navController.viewControllers
        controllers.insert(controller, at: 0)
        navController.setViewControllers(controllers, animated: false)
    }

}
