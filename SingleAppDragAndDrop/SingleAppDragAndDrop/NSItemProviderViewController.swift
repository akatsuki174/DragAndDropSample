import UIKit

class NSItemProviderViewController: UIViewController {

    @IBOutlet weak var dragableImageView1: UIImageView!
    @IBOutlet weak var dragableImageView2: UIImageView!

    @IBOutlet weak var dropImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // ドラッグに対応させるためにUIDragInteractionを追加
        dragableImageView1.addInteraction(UIDragInteraction(delegate: self))
        dragableImageView2.addInteraction(UIDragInteraction(delegate: self))
        // ドロップに対応させるためにUIDropInteractionsを追加
        dropImageView.addInteraction(UIDropInteraction(delegate: self))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
extension NSItemProviderViewController: UIDragInteractionDelegate {

    // ドラッグ開始時に呼ばれる
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        // ドラッグできるデータがなければ空配列を返す
        guard let imageView = interaction.view as? UIImageView,
            let image = imageView.image else {
            return []
        }

        let itemProvider = NSItemProvider(object: image)
        return [UIDragItem(itemProvider: itemProvider)]
    }
}

extension NSItemProviderViewController: UIDropInteractionDelegate {

    // 何のオブジェクトを許容するか指定
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }

    // ドロップ時の挙動を定義
    // ドラッグがviewの領域に入っている時に呼び出される
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let location = session.location(in: self.view)
        let dropOperation: UIDropOperation?
        if session.canLoadObjects(ofClass: UIImage.self) {
            if dropImageView.frame.contains(location) {
                dropOperation = .copy
            } else {
                dropOperation = .cancel
            }
        } else {
            dropOperation = .cancel
        }

        return UIDropProposal(operation: dropOperation!)
    }

    // ドロップされた時の挙動を定義
    // 実際にドロップされる時に呼び出される
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard session.canLoadObjects(ofClass: UIImage.self) else { return }
        // ドラッグされていたデータを取得
        session.loadObjects(ofClass: UIImage.self) { (items) in
            if let images = items as? [UIImage] {
                self.dropImageView.image = images.last
            }
        }
    }
}
