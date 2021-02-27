import RxSwift
import Foundation

let observeQueue1 = DispatchQueue(label: "observeQueue1")
let subscribeQueue = DispatchQueue(label: "subscribeQueue")
let observeQueue2 = DispatchQueue(label: "observeQueue2")

let _ = Observable.just(1)
    .do(onNext: { value in
        // subscribe(on:)によって切り替えられたsubscribeQueueによって処理される
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        precondition(label == "subscribeQueue")
    })
    .observe(on: ConcurrentDispatchQueueScheduler(queue: observeQueue1))
    .map { value -> Int in
        // observe(on:)によって切り替えられたobserveQueue1で実行される。
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        precondition(label == "observeQueue1")
        // subscribe(on:)によって切り替えられたあと、イベント受け取り時の
        // キューをobserve(on:)によって切り替えられたため。

        return value * 10
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(queue: subscribeQueue))
    .observe(on: ConcurrentDispatchQueueScheduler(queue: observeQueue2))
    .subscribe(onNext: { value in
        // observe(on:)によって切り替えられたobserveQueue2によって処理される。
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        precondition(label == "observeQueue2")
        // observeQueue1の処理結果のイベントをobserveQueue2で受け取るため。

        print(value) // => 10
    })
