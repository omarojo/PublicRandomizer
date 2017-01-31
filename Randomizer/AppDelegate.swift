import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize the window
        window = UIWindow.init(frame: UIScreen.main.bounds)
        
        // Set Background Color of window
        window?.backgroundColor = UIColor.yellow
        
        // Allocate memory for an instance of the 'MainViewController' class
        let mainViewController = ViewController()
        
        // Set the root view controller of the app's window
        window!.rootViewController = mainViewController
        
        // Make the window visible
        window!.makeKeyAndVisible()
        
        return true
    }  
 

    func applicationWillResignActive(_ application: UIApplication) {
        // Pause camera
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Pause camera
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume camera
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Pause camera if not already
    }


}

