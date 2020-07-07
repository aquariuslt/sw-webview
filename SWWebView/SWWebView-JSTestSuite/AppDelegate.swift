import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var controller: ViewController?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.controller = ViewController()
        self.window!.rootViewController = self.controller
        self.window!.makeKeyAndVisible()
        return true
    }
}
