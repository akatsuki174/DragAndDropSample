import UIKit

class PanGestureViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func transform(for translation: CGPoint) -> CGAffineTransform {
        let moveBy = CGAffineTransform(translationX: translation.x, y:  translation.y)
        let rotation = -sin(translation.x / (imageView.frame.width * 4.0))
        return moveBy.rotated(by: rotation)
    }

    @IBAction func panAction(_ sender: UIPanGestureRecognizer) {
        let move: CGPoint = sender.translation(in: view)
        sender.view!.center.x += move.x
        sender.view!.center.y += move.y
        sender.setTranslation(CGPoint.zero, in:view)
    }

}
