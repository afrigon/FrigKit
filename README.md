# FrigKit
A Swift army knife

## Table of Content

- [Request]: https://github.com/afrigon/FrigKit#request	"Request Link" test

## Request

The request module can be used to send HTTP request over the network using the URLSession API.

### Examples

The most basic request is done using the `text` method on a `Request` instance. A simple `GET` request will be done and a string containing the result will be stored in `response.text`.

```swift
Request("https://example.com").text { response in
    guard response.error == nil else {
        return // handle error
    }

    print(response.text)
}
```

Most times you'll be using APIs and JSON response to represent your objects. The `object` method is a generic type that will automatically decode your json data to Swift objects.

```swift
struct Cat: Decodable {
    let name: String
    let age: Int
}

Request("https://example.com/cats.json").object { (response: ObjectResponse<[Cat]>) in
    guard response.error == nil else {
        return // handle error
    }

    guard let cats = response.object else {
        return // no cats :(                                                 
    }
                                                 
    for cat in cats {
        print("\(cat.name) is \(cat.age) years old")   
    }
}
```

