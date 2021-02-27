import RxSwift
import Foundation

let subscribeQueueA = DispatchQueue(label: "subscribeQueueA")
let subscribeQueueB = DispatchQueue(label: "subscribeQueueB")
let subscribeQueueC = DispatchQueue(label: "subscribeQueueC")

// Observerが増えてもカウントが1よりアップしないことを保証したい
var count = 0

// 念の為に書くと、ここはメインスレッドで呼び出している
let stream = Observable.just(1)
    .flatMap { value -> Observable<Int> in
        .create { observer in
            count += 1
            // 1.
            precondition(count == 1)

            // 2. 同期実行のため呼び出しキューのスレッドでそのまま処理される
            // 最初に接続されたObserverAのキューにより実行される
            let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
            print(".create: [\(label)]") // => "[com.apple.main-thread]"

            observer.onNext(value * 10)
            return Disposables.create()
        }
    }
    .publish()

// ObserverAによるsubscribe
stream
    .map { value -> Int in
        // キューはメインキューによって処理される
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("mapA: [\(label)]") // => "[com.apple.main-thread]"
        // 3. このObserverが先に接続されてもconnect時に値が流れるため

        return value * 2
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(queue: subscribeQueueA))
    .observe(on: MainScheduler.instance)
    .subscribe(onNext: { _ in
        assert(Thread.isMainThread)
    })

// ObserverBによるsubscribe
stream
    .map { value -> Int in
        // キューはメインキューによって処理される
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("mapB: [\(label)]") // => "[com.apple.main-thread]"
        // 4. このObserverが先に接続されてもconnect時に値が流れるため

        return value / 2
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(queue: subscribeQueueB))
    .observe(on: MainScheduler.instance)
    .subscribe(onNext: { _ in
        assert(Thread.isMainThread)
    })

// ObserverCによるsubscribe
stream
    .map { value -> Int in
        // こちらはsubscribeQueueCで実行できる
        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("mapC: [\(label)]") // => "[com.apple.main-thread]"
        // 5. このObserverが先に接続されてもconnect時に値が流れるため

        return value - 2
    }
    .subscribe(on: ConcurrentDispatchQueueScheduler(queue: subscribeQueueC))
    .observe(on: MainScheduler.instance)
    .subscribe(onNext: { _ in
        assert(Thread.isMainThread)
    })

// ここで上流ストリームを流し始める
stream.connect()
