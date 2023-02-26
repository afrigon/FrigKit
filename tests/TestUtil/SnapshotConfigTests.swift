@testable import SwiftnessTestKit

final class SnapshotConfigTests: XCTestCase {
    private func assertDescription(_ config: SnapshotConfig, toBe expected: String) {
        expect(config.description).to(equal(expected))
    }

    func test_phone_description() {
        assertDescription(.phone, toBe: "phone")
    }

    func test_phone_landscape_description() {
        assertDescription(.phoneLandscape, toBe: "phone-landscape")
    }

    func test_tablet_description() {
        assertDescription(.tablet, toBe: "tablet")
    }

    func test_tablet_landscape_description() {
        assertDescription(.tabletLandscape, toBe: "tablet-landscape")
    }

    func test_tv_description() {
        assertDescription(.tv, toBe: "tv")
    }

    func test_phone_dark_description() {
        assertDescription(.phone.dark, toBe: "phone-dark")
    }

    func test_phone_rtl_description() {
        assertDescription(.phone.rtl, toBe: "phone-rtl")
    }

    func test_hight_contrast_description() {
        assertDescription(.phone.highContrast, toBe: "phone-high-contrast")
    }

    func test_small_font_description() {
        assertDescription(.phone.smallText, toBe: "phone-small-font")
    }

    func test_large_font_description() {
        assertDescription(.phone.largeText, toBe: "phone-large-font")
    }

    func test_fixed_description() {
        assertDescription(.fixed(width: 100, height: 200), toBe: "100x200")
    }

    func test_fit_description() {
        assertDescription(.fit, toBe: "fit")
    }

    private func size(of config: SnapshotConfig) -> CGSize {
        guard case let .device(device) = config.layout else {
            fail("configuration is not a device")
            return .zero
        }

        return device.size
    }

    private func safeArea(of config: SnapshotConfig) -> UIEdgeInsets {
        guard case let .device(device) = config.layout else {
            fail("configuration is not a device")
            return .zero
        }

        return device.safeArea
    }

    func test_phone_size() {
        let value = size(of: .phone)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_phone_safe_area() {
        let value = safeArea(of: .phone)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_phone_landscape_size() {
        let value = size(of: .phoneLandscape)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_phone_landscape_safe_area() {
        let value = safeArea(of: .phoneLandscape)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_tablet_size() {
        let value = size(of: .tablet)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_tablet_safe_area() {
        let value = safeArea(of: .tablet)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_tablet_landscape_size() {
        let value = size(of: .tabletLandscape)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_tablet_landscape_safe_area() {
        let value = safeArea(of: .tabletLandscape)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_tv_size() {
        let value = size(of: .tv)
        assertSnapshot(matching: value, as: .dump)
    }

    func test_tv_safe_area() {
        let value = safeArea(of: .tv)
        assertSnapshot(matching: value, as: .dump)
    }
}
