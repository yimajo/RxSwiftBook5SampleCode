import RxSwift
import Foundation

let subscribeQueue = DispatchQueue(label: "subscribeQueue")

let _ = Observable.just(1)
    .map { value -> Int in
        // ここはメインスレッドではない。
        precondition(!Thread.isMainThread)
        // その理由は、observe(on:)により、
        // 平行に処理を行うためのConcurrentDispatchQueueSchedulerが
        // メインキューでないDispatchQueueを利用しているため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("map: [\(label)]") // => "[subscribeQueue]"

        return value * 10
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(queue: subscribeQueue))
    .observe(on: MainScheduler.instance)
    .subscribe(onNext: { _ in
        // ここはメインスレッドで実行される。
        precondition(Thread.isMainThread)
        // その理由は、observe(on:)により、MainSchedulerに切り替えられているため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("onNext: [\(label)]") // => "[com.apple.main-thread]"
    })
