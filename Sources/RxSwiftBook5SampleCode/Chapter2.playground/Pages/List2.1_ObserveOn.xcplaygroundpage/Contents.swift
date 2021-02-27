import RxSwift
import Foundation

// 並列実行用のキューに名前を付けてデバッグしやすいようにします
let observeQueue = DispatchQueue(label: "observeQueue")

let _ = Observable.just(1)
    .map { value -> Int in
        // ここはメインスレッドで実行される。
        precondition(Thread.isMainThread)
        // その理由は、このストリームの呼び出しがメインスレッドなため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("map: [\(label)]") // => "[com.apple.main-thread]”

        return value * 10
    }
    .observe(on: ConcurrentDispatchQueueScheduler(queue: observeQueue))
    .subscribe(onNext: { _ in
        // ここはメインスレッドではない。
        precondition(!Thread.isMainThread)
        // その理由は、observe(on:)により、
        // 平行に処理を行うためのConcurrentDispatchQueueSchedulerが
        // メインキューでないDispatchQueueを利用しているため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("onNext: [\(label)]") // => "[observeQueue]"

        precondition(label == "observeQueue")
    })
