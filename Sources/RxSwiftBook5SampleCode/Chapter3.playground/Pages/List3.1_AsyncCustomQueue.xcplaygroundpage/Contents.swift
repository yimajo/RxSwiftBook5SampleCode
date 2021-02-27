import RxSwift
import Foundation

// 非同期実行のためのカスタムキューを用意
let customQueue = DispatchQueue(label: "customQueue")

let _ = Observable.just(1)
    .flatMap { value -> Observable<Int> in
        .create { observer in
            customQueue.async {
                // ここはメインスレッドで実行されない
                precondition(!Thread.isMainThread)
                // その理由は、カスタムキューで非同期実行されるから

                observer.onNext(value * 10)
            }

            return Disposables.create()
        }
    }
    .filter {
        // ここはメインスレッドで実行されない
        assert(!Thread.isMainThread)

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("filter: [\(label)]") // => "[customQueue]"

        // 0じゃないイベント要素なら通す
        return $0 != 0
    }
    .subscribe(onNext: { value in
        // ここはメインスレッドで実行されない
        assert(!Thread.isMainThread)
        // その理由は、独自の非同期キューに切り替えられ、
        // その結果を受けたため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        precondition(label == "customQueue")

        print(value)
    })

/*
 ストリームの処理自体が独自のキューによる実行されると、
 そのストリームの処理自体が独自のキューのスレッドに切り替えられる。

 これはNSURLSeesionなどのiOS標準の通信も、Core Dataなどの非同期処理も同じ。
 さらにサードパーティ製ライブラリも非同期処理をしているので、
 ストリームは切り替えられている。
 */

