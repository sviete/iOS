import HAKit
import PromiseKit
import Shared

struct OnboardingAuthStepConfig: OnboardingAuthPostStep {
    var api: HomeAssistantAPI
    var sender: UIViewController

    static var supportedPoints: Set<OnboardingAuthStepPoint> {
        Set([.afterRegister])
    }

    func perform(point: OnboardingAuthStepPoint) -> Promise<Void> {
        api.getConfig()
    }
}
