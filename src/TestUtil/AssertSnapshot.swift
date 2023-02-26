import SwiftUI
import SnapshotTesting

public func assert(
    view: @autoclosure () throws -> some View,
    with configs: [SnapshotConfig],
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    assertSnapshots(
        matching: try? view(),
        as: configs.reduce(into: .init(), { acc, config in
            acc[config.description] = .image(
                layout: config.snapshotLayout,
                traits: config.traits
            )
        }),
        file: file,
        testName: testName,
        line: line
    )
}
