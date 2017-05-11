import UIKit
import RxSwift
import RxCocoa

class ModelTableViewController: UIViewController {
    private var viewModel: ViewModel?
    private var models: [Model] = []

    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))

        view.addSubview(activityIndicator)
        activityIndicator.center = view.center

        let refreshTrigger = rx.sentMessage(#selector(viewWillAppear))
            .take(1)
            .map { _ in }
        let loadMoreTrigger = tableView.rx.willDisplayCell
            .filter { [weak self] (cell, indexPath) -> Bool in
                guard let strongSelf = self else { return false }
                let isLastCell = indexPath.row == strongSelf.tableView.numberOfRows(inSection: indexPath.section) - 1
                return isLastCell
            }
            .map { _ in }

        let viewModel = ViewModel(inputs: (refreshTrigger: refreshTrigger, loadMoreTrigger: loadMoreTrigger))

        viewModel.models
            .bind(to: tableView.rx.items(cellIdentifier: String(describing: UITableViewCell.self))) { (row, model, cell) in
                cell.textLabel?.text = model.name
            }
            .disposed(by: disposeBag)

        viewModel.networkStates
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] networkState in
                guard let strongSelf = self else { return }

                strongSelf.activityIndicator.stopAnimating()

                switch networkState {
                case .nothing:
                    break
                case .requesting:
                    strongSelf.activityIndicator.startAnimating()
                case let .error(error):
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                    strongSelf.present(alertController, animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)

        self.viewModel = viewModel
    }
}
