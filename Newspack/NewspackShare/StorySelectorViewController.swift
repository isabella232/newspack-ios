import UIKit
import NewspackFramework

protocol StorySelectorViewControllerDelegate: UIViewController {
    func didSelectStory(story: ShadowStory)
}

class StorySelectorViewController: UITableViewController {

    var shadowSites: [ShadowSite]!
    weak var delegate: StorySelectorViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureStyle()
    }

    func configureStyle() {

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return shadowSites.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shadowSites[section].stories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCellIdentifier", for: indexPath)
        let story = shadowSites[indexPath.section].stories[indexPath.row]

        cell.textLabel?.text = story.title

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return shadowSites[section].title
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let story = shadowSites[indexPath.section].stories[indexPath.row]
        delegate?.didSelectStory(story: story)
    }

}
