// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Combine
import mbientSwiftUI
import MetaWear
import MetaWearSync

public class Routing: ObservableObject {

    /// Programmatically-chosen screen
    @Published private(set) var destination: Destination = .choose
    /// Focused item + configs set prior to navigation, read once in VM init or by `UIFactory`
    private(set) var focus: (item: Item, configs: [ModulesConfiguration], sessionNickname: String)? = nil

    /// Coordinate view custom animations
    public private(set) lazy var willTransitionFrom = notifyWillTransitionFrom.eraseToAnyPublisher()
    
    private let notifyWillTransitionFrom = CurrentValueSubject<Destination,Never>(.choose)

    /// Stand-in for macOS, which lacks a SwiftUI a navigation stack. The system handles this on iOS.
    private var history = [Destination]()
}

// MARK: - Intents

public extension Routing {

    /// Use programmatic navigation stack (macOS) that on iOS may differ from the system stack.
    /// Resets focus on navigating to `.choose`.
    ///
    func goBack() {
        guard let last = history.popLast() else { return }
        self.destination = last
        if destination == .choose { focus = nil }
    }

    func goBack(until destination: Destination) {
        while let last = history.popLast() {
            if last == destination {
                self.destination = last
                if destination == .choose { focus = nil }
                break
            }
        }
    }

    /// Programatic navigation.
    /// Set focus before calling destinations other than `.choose`.
    ///
    func setDestination(_ next: Destination) {
        self.history.append(destination)
        if next == .choose { focus = nil }
        self.destination = next // Triggers a diff
    }

    /// Programmatic navigation's focused item.
    /// Navigating to `choose` automatically removes focus.
    ///
    func setNewFocus(item: Item) {
        self.focus = (item, [], "")
    }

    /// Programmatic navigation's focused item's configs.
    /// Must be previously focused.
    ///
    func setConfigs(_ configs: [ModulesConfiguration], sessionNickname: String) {
        guard let item = focus?.item else { fatalError() }
        focus = (item, configs, sessionNickname)
    }

    /// Set programmatic navigation's downloadable session from memory.
    /// Must be previously focused.
    ///
    func setSessionName(_ nickname: String) {
        guard let item = focus?.item else { fatalError() }
        focus = (item, focus?.configs ?? [], nickname)
    }
}

// MARK: - Model

public extension Routing {

    enum Destination: Hashable, Equatable {
        case choose
        case history
        case configure
        case stream
        case log
        case downloadLogs
    }

    enum Item: Hashable, Equatable {
        case group(UUID)
        case known(MACAddress)
    }
}
