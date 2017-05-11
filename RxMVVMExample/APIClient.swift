import Foundation
import RxSwift

enum NextPage {
    case nextPage(Int)
    case reachedLast
}

struct ModelRequest {
    enum RequestKind {
        case refresh, loadMore
    }

    var page: Int
    var requestKind: RequestKind

    struct Response {
        var requestKind: RequestKind
        var models: [Model]
        var nextPage: NextPage
    }
}

struct MockClient {
    static let stubResponse: [ModelRequest: ModelRequest.Response] = [
        ModelRequest(page: 1, requestKind: .refresh): ModelRequest.Response(
            requestKind: .refresh,
            models: (0..<20).map { Model(name: "No. \($0)") },
            nextPage: .nextPage(2)
        ),
        ModelRequest(page: 2, requestKind: .loadMore): ModelRequest.Response(
            requestKind: .refresh,
            models: (20..<40).map { Model(name: "No. \($0)") },
            nextPage: .nextPage(3)
        ),
        ModelRequest(page: 3, requestKind: .loadMore): ModelRequest.Response(
            requestKind: .refresh,
            models: (40..<50).map { Model(name: "No. \($0)") },
            nextPage: .reachedLast
        ),
    ]

    static func response(to request: ModelRequest) -> Single<ModelRequest.Response> {
        if let response = stubResponse[request] {
            return Single<ModelRequest.Response>.create { observer -> Disposable in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    observer(.success(response))
                })
                return Disposables.create()
            }
        } else {
            return Single<ModelRequest.Response>.create { observer -> Disposable in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    observer(.error(MockClientError.error))
                })
                return Disposables.create()
            }
        }
    }

    enum MockClientError: Error {
        case error
    }
}

extension ModelRequest: Hashable {
    var hashValue: Int {
        return page
    }
}

func == (lhs: ModelRequest, rhs: ModelRequest) -> Bool {
    return lhs.page == rhs.page
}
