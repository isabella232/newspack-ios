import Foundation
import WordPressShared

class UserView: UIStackView {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var spacer: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        Appearance.style(userView: nameLabel, imageView: imageView)
    }

    func configure(with name: String, gravatar: URL?) {
        nameLabel.text = name

        if let url = gravatar, let photonURL = PhotonImageURLHelper.photonURL(with: imageView.frame.size, forImageURL: url) {
            imageView.downloadImage(from: photonURL)
        }
    }
}
