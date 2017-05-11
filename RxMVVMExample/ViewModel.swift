import Foundation
import RxSwift
import RxCocoa

class ViewModel {
    enum TriggerType {
        case refresh, loadMore
    }

    enum NetworkState {
        case nothing
        case requesting
        case error(Error)
    }

    var models: Observable<[Model]> = Observable.empty()

    private let networkState: Variable<NetworkState> = Variable(.nothing)
    var networkStates: Observable<NetworkState> {
        return networkState.asObservable()
    }

    private static let initialPage: Int = 1
    private var nextPage: NextPage = .nextPage(ViewModel.initialPage)
    private let disposeBag = DisposeBag()

    init(inputs: (refreshTrigger: Observable<Void>, loadMoreTrigger: Observable<Void>)) {
        let requestTrigger: Observable<TriggerType> = Observable
            .merge(
                inputs.refreshTrigger.map { .refresh },
                inputs.loadMoreTrigger.map { .loadMore }
            )

        models = requestTrigger
            .flatMapFirst { [weak self] type -> Observable<ModelRequest.Response> in
                guard let strongSelf = self else { return .empty() }

                let request: ModelRequest
                switch type {
                case .refresh:
                    request = ModelRequest(page: ViewModel.initialPage, requestKind: .refresh)
                case .loadMore:
                    switch strongSelf.nextPage {
                    case let .nextPage(page):
                        request = ModelRequest(page: page, requestKind: .loadMore)
                    case .reachedLast:
                        return .empty()
                    }
                }

                let response = MockClient.response(to: request)
                return response.asObservable()
                    .do(onSubscribed: { [weak self] in
                        self?.networkState.value = .requesting
                    }, onDispose: { [weak self] in
                        self?.networkState.value = .nothing
                    })
                    .catchError { [weak self] error -> Observable<ModelRequest.Response> in
                        self?.networkState.value = .error(error)
                        return .empty()
                    }
                }
            .do(onNext: { [weak self] response in
                self?.nextPage = response.nextPage
            })
            .scan([]) { (models, response) -> [Model] in
                switch response.requestKind {
                case .refresh:
                    return response.models
                case .loadMore:
                    return models + response.models
                }
            }
            .startWith([])
            .shareReplay(1)
    }
}
