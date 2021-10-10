import Eureka
import Reachability
import Shared
import UIKit

class OnboardingNavigationViewController: UINavigationController, RowControllerType {
    public var onDismissCallback: ((UIViewController) -> Void)?

    // swiftlint:disable:next force_try
    let reachability = try! Reachability()

    override var childForStatusBarStyle: UIViewController? {
        nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        view.tintColor = Current.style.onboardingTintColor

        if #available(iOS 13, *) {
            overrideUserInterfaceStyle = .dark
        }

        if #available(iOS 13, *) {
            let appearance = with(UINavigationBarAppearance()) {
                $0.configureWithOpaqueBackground()
                $0.backgroundColor = Current.style.onboardingBackground
                $0.shadowColor = .clear
                $0.titleTextAttributes = [ .foregroundColor: UIColor.white ]
            }
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.tintColor = .white
        } else {
            navigationBar.setBackgroundImage(
                UIImage(size: CGSize(width: 1, height: 1), color: Current.style.onboardingBackground),
                for: .default
            )
            navigationBar.shadowImage = UIImage(size: CGSize(width: 1, height: 1), color: .clear)
        }

        if viewControllers.isEmpty {
            viewControllers = [ WelcomeViewController() ]
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        do {
            try reachability.startNotifier()
        } catch {
            Current.Log.error("Unable to start Reachability notifier: \(error)")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reachability.stopNotifier()
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
        onDismissCallback?(self)
    }

    func styleButton(_ button: UIButton) {
        Current.style.onboardingButtonPrimary(button)
    }

    override func show(_ vc: UIViewController, sender: Any?) {
        if let vc = vc as? ConnectionErrorViewController, let sender = sender as? UIViewController {
            // we don't check if we're _going_ to replace, in case the user tapped 'back' first
            setViewControllers(viewControllers.map {
                if $0 == sender {
                    return vc
                } else {
                    return $0
                }
            }, animated: false)
        } else {
            super.show(vc, sender: sender)
        }
    }
}

extension OnboardingNavigationViewController: UINavigationControllerDelegate {
    private func updateNavigationBar(for controller: UIViewController?, animated: Bool) {
        let hiddenNavigationBarClasses: [UIViewController.Type] = [
            WelcomeViewController.self,
            IndividualPermissionViewController.self,
        ]

        if let controller = controller,
           hiddenNavigationBarClasses.contains(where: { type(of: controller) == $0 }) {
            setNavigationBarHidden(true, animated: animated)
        } else {
            setNavigationBarHidden(false, animated: animated)
        }
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        updateNavigationBar(for: viewController, animated: animated)

        self.transitionCoordinator?.animate(alongsideTransition: { _ in
            // putting the navigation bar change here causes the bar to animate in/out
        }, completion: { [weak self] context in
            if context.isCancelled {
                self?.updateNavigationBar(for: self?.topViewController, animated: animated)
            }
        })
    }
}
