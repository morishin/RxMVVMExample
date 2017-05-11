import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }
}

fileprivate class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton()
        button.setTitle("Next", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.sizeToFit()
        view.backgroundColor = .white
        view.addSubview(button)
        button.center = view.center
        button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
    }
    func didTapButton(_ sender: UIButton) {
        let controller = ModelTableViewController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
}
