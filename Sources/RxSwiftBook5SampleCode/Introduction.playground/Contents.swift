import RxSwift
import Foundation

let _ = Observable.of(1)
    .flatMap { value -> Observable<Int> in
        // 1. ここの処理がメインスレッドで動作しない理由が説明できますか？
        print("flatMap: \(Thread.isMainThread)") // => flatMap: false
        precondition(!Thread.isMainThread)

        return .create { observer in
            DispatchQueue.global().async {
                observer.onNext(value * 10)
            }
            return Disposables.create()
        }
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
    .subscribe(onNext: { _ in
        // 2. このキューがグローバルキューで実行される理由は説明できますか？
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("onNext: [\(label)]") // => [com.apple.root.default-qos]
    })
