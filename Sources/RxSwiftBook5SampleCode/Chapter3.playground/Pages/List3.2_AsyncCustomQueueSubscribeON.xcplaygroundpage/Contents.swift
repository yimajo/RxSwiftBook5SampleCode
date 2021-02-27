import RxSwift
import Foundation

// 非同期実行のためのカスタムキューを用意
let customQueue = DispatchQueue(label: "customQueue")

// 上流を制御するつもりのキューを用意
let subscribeQueue = DispatchQueue(label: "subscribeQueue")

let _ = Observable.just(1)
    .flatMap { value -> Observable<Int> in
        // ここはメインスレッドで実行されない
        precondition(!Thread.isMainThread)
        // その理由は、subscribe(on:)により[subscribeQueue]で実行されるため

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("flatMap: [\(label)]") // => "[subscribeQueue]"
        // subscribe(on:)で指定した[subscribeQueue]となる
        precondition(label == "subscribeQueue")

        return .create { observer in
            customQueue.async {
                // ここはメインスレッドで実行されない
                assert(!Thread.isMainThread)
                // その理由は、グローバルキューで実行されるから
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
        // さらにsubscribe(on:)で指定した[subscribeQueue]でもない
        precondition(label != "subscribeQueue")

        // 0じゃないイベント要素なら通す
        return $0 != 0
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(queue: subscribeQueue))
    .subscribe(onNext: { value in
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("onNext: [\(label)]") // => "customQueue"
        precondition(label == "customQueue")

        print(value)
    })

/*
 通信などでは独自の非同期キュー実行が行われる。
 しかしsubscribe(on:)は呼び出しに関してのみ制御できる。
 もちろん呼び出しを制御しても独自キューでの実行後のストリームは切り替えられたキューが有効。

 もし、通信後のキューをfilterなどの前に制御したいなら、
 observe(on:)を利用したら良い

 */
