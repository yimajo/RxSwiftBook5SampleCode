import RxSwift
import Foundation

enum WebAPIError: Error {
    case unknownStatus
    case noData
}

func fetchNumberFact(_ number: Int) -> Observable<String> {
    .create { observer in
        let url = URL(string: "http://numbersapi.com/\(number)/trivia")!

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // ここはメインスレッドで実行されない
            precondition(!Thread.isMainThread)
            // その理由は、URLSessionはキューを指定しなければ内部キューで処理されるため。

            let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
            print("URLSession: \(label)") // => "com.apple.NSURLSession-delegate"

            if let error = error {
                observer.onError(error)
                return
            }

            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {

                observer.onError(WebAPIError.unknownStatus)
                return
            }

            guard let data = data else {
                observer.onError(WebAPIError.noData)
                return
            }

            observer.onNext(String(decoding: data, as: UTF8.self))
        }

        task.resume()
        return Disposables.create()
    }
}

let _ = Observable.just(1)
    .flatMap { value -> Observable<String> in
        fetchNumberFact(value)
    }
    .subscribe(onNext: { _ in
        // ここはメインスレッドで実行されない
        precondition(!Thread.isMainThread)
        // その理由は、URLSessionのキューをこちらが指定しないため
        // 独自の非同期キューに切り替えられているため。

        let label = String(validatingUTF8: __dispatch_queue_get_label(nil))!
        print("onNext: \(label)") // => "com.apple.NSURLSession-delegate"
    })
