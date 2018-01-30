import UIKit
import AVFoundation
import MobileCoreServices

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
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = image
        return [dragItem]
    }

    // 複数のドラッグに対応
    func dragInteraction(_ interaction: UIDragInteraction, itemsForAddingTo session: UIDragSession, withTouchAt point: CGPoint) -> [UIDragItem] {
        guard let imageView = interaction.view as? UIImageView,
            let image = imageView.image else {
                return []
        }
        for item in session.items {
            // 異なる種類のアイテムが含まれていたら追加しない
            guard item.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) else {
                return []
            }
            // すでに含まれている場合は追加しない
            // ドラッグ開始時にlocalObjectプロパティにオブジェクトを登録しておけば同一かどうか判定できる
            guard (item.localObject as? UIImage) != image else {
                return []
            }
        }
        let itemProvider = NSItemProvider(object: image)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = image
        return [dragItem]
    }

    // リフト中のプレビューをカスタマイズする
    // UITargetedDragPreviewはプレビューを表すクラスで、任意のUIViewオブジェクトを指定できる
    // デフォルトのプレビューはUIDragInteractionを追加した対象のview全体になる
    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        guard let imageView = interaction.view as? UIImageView,
            let image = imageView.image else {
                return nil
        }
        let preview = UIImageView(image: image)
        // アスペクト比を保ったまま任意のCGRectに収める
        preview.frame.size = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds).size

        // 背景色、プレビューの形状を設定
        let parameters = UIDragPreviewParameters()
        let center = imageView.convert(imageView.center, from: imageView.superview)
        // プレビューの表示位置を指定
        let target = UIDragPreviewTarget(container: imageView, center: center)
        return UITargetedDragPreview(view: preview, parameters: parameters, target: target)
    }

    // ドラッグがキャンセルされた時のプレビューをカスタマイズする
    // defaultPreviewにリフト時のプレビューが入っている
    // プレビュー時のアニメーションはiOSによって管理されている
    func dragInteraction(_ interaction: UIDragInteraction, previewForCancelling item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        guard let imageView = interaction.view as? UIImageView else {
            return nil
        }

        let center = imageView.convert(imageView.center, from: imageView.superview)
        let target = UIDragPreviewTarget(container: imageView, center: center)
        return defaultPreview.retargetedPreview(with: target)
    }

    // デフォルトだとプレビューは小さいサイズで表示される（ドロップしたい領域が隠れないように）
    // UITableViewCellの並べ替えなど、フルサイズの方が自然な場合はこのメソッドでtrueを返す
    func dragInteraction(_ interaction: UIDragInteraction, prefersFullSizePreviewsFor session: UIDragSession) -> Bool {
        return true
    }

    // ドラッグのアニメーションに合わせて他の要素もアニメーションさせる
    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        guard let imageView = interaction.view as? UIImageView else { return }
        // リフトの開始に合わせたアニメーションを追加
        animator.addAnimations {
            imageView.alpha = 0.3
        }
        // リフトが終了するのに合わせたアニメーションを追加
        animator.addCompletion { position in
            switch position {
            case .start, .end:
                imageView.alpha = 1.0
            case .current:
                break
            }
        }
    }

    // ドラッグがキャンセルされた時のアニメーションを設定
    func dragInteraction(_ interaction: UIDragInteraction, item: UIDragItem, willAnimateCancelWith animator: UIDragAnimating) {
        guard let imageView = interaction.view as? UIImageView else { return }
        animator.addAnimations {
            imageView.alpha = 1.0
        }
    }

    // 同一アプリ内でコピーではなく移動をサポートする場合はtrueを返す
    // その際、ドロップ先ではUIDropProposalに.moveを設定する
    func dragInteraction(_ interaction: UIDragInteraction, sessionAllowsMoveOperation session: UIDragSession) -> Bool {
        return true
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
