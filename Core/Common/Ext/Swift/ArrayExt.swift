//
//  ArrayExt.swift
//
//
//  Created by MK on 2021/6/16.
//

import Foundation

public extension Array {
    func at(_ index: Int) -> Element? {
        guard index >= 0, index < count else {
            return nil
        }
        return self[index]
    }

    func indexOf(next: Bool, from index: Int) -> Int {
        var target = index
        if next {
            target += 1
        } else {
            target -= 1
        }

        if target >= count {
            target = 0
        } else if target < 0 {
            target = count - 1
        }
        return target
    }

    func expand(by sepBuilder: () -> Element) -> [Element] {
        var list = [Element]()
        for (index, element) in enumerated() {
            if index != 0 {
                list.append(sepBuilder())
            }
            list.append(element)
        }
        return list
    }
}

public extension Array where Element: Equatable {
    func element(next: Bool, by source: Element) -> Element? {
        guard let index = firstIndex(of: source) else {
            return nil
        }
        let targetIndex = indexOf(next: next, from: index)
        return at(targetIndex)
    }
}
