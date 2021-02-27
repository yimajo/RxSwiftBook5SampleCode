import RxSwift
import Foundation

let subscribeQueue = DispatchQueue(label: "subscribeQueue")

let _ = Observable.just(1)
    .map { value -> Int in
        // ここはメインスレッドではない。
        precondition(!Thread.isMainThread)
        // その理由は、subscribe(on:)により、
        // 平行に処理を行うためのConcurrentDispatchQueueSchedulerが
        // メインキューでないDispatchQueueを利用しているため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("map: [\(label)]") // => "[subscribeQueue]"

        return value * 10
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(queue: subscribeQueue))
    .subscribe(onNext: { _ in
        // ここはメインスレッドではない。
        precondition(!Thread.isMainThread)
        // その理由は、subscribe(on:)により、
        // 平行に処理を行うために切り替えられ、
        // その時点からキューが切り替えられてないため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("onNext: queue \(label)") // => "[subscribeQueue]"
    })
