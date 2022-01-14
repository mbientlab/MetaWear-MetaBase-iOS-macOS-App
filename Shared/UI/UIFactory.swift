// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import MetaWear
import MetaWearSync
import mbientSwiftUI
import Combine

public class UIFactory: ObservableObject {

    public init(_ devices:  MetaWearSyncStore,
                _ sessions: SessionRepository,
                _ presets:  PresetSensorParametersStore,
                _ logging:  ActiveLoggingSessionsStore,
                _ importer: MetaBase4SessionDataImporter,
                _ scanner:  MetaWearScanner,
                _ routing:  Routing,
                _ defaults: UserDefaultsContainer,
                _ launches: LocalLaunchCounter,
                _ onboard:  OnboardState
    ) {
        self.presets = presets
        self.devices = devices
        self.sessions = sessions
        self.scanner = scanner
        self.importer = importer
        self.routing = routing
        self.logging = logging
        self.defaults = defaults
        self.launches = launches
        self.onboard = onboard
    }

    private unowned let defaults: UserDefaultsContainer
    private unowned let devices:  MetaWearSyncStore
    private unowned let sessions: SessionRepository
    private unowned let presets:  PresetSensorParametersStore
    private unowned let logging:  ActiveLoggingSessionsStore
    private unowned let importer: MetaBase4SessionDataImporter
    private unowned let scanner:  MetaWearScanner
    private unowned let routing:  Routing
    private unowned let launches: LocalLaunchCounter
    private unowned let onboard:  OnboardState
    private lazy var actionQueue  = _makeBackgroundQueue(named: "action")
}

public extension UIFactory {

    // MARK: - First Launch(es)

    func makeImportVM() -> MigrateDataPanelVM {
        .init(importer: importer)
    }

    func makeMigrationVM() -> MigrationSessionVM {
        .init(didOnboard: onboard.didOnboard, canMigrate: onboard.canMigrate)
    }

    func makeOnboardingSessionVM() -> OnboardingSessionVM {
        .init(didOnboard: onboard.didOnboard, canMigrate: onboard.canMigrate, launchCounter: launches, defaults: defaults)
    }

    func makeOnboardState() -> OnboardState {
        onboard
    }

    // MARK: - First Screen

    func makeDiscoveredDeviceListVM() -> DiscoveryListVM {
        .init(scanner: scanner, store: devices)
    }

    func makeBluetoothStateWarningsVM() -> BluetoothStateVM {
        .init(scanner: scanner)
    }

    func makeMetaWearItemVM(_ item: Routing.Item) -> KnownItemVM {
        switch item {
            case .known(let mac):
                guard let known = devices.getDeviceAndMetadata(mac)
                else { fatalError() }
                return .init(device: known, store: devices, logging: logging, routing: routing, queue: actionQueue)

            case .group(let id):
                guard let group = devices.getGroup(id: id)
                else { fatalError() }
                return .init(group: group, store: devices, logging: logging, routing: routing, queue: actionQueue)
        }
    }

    func makeUnknownItemVM(_ id: CBPeripheralIdentifier) -> UnknownItemVM {
        .init(cbuuid: id, store: devices, logging: logging, routing: routing)
    }

    // MARK: - Device History & Details

    func makeAboutDeviceVM(device: MWKnownDevice) -> AboutDeviceVM {
        .init(device: device, store: devices, logging: logging, routing: routing)
    }

    func makeHistoryScreenVM() -> HistoryScreenVM {
        guard let focus = routing.focus else { fatalError("Set focus before navigation") }
        let (title, metawears) = getKnownDevices(for: focus.item)
        let vms = makeAboutVMs(for: metawears)
        return .init(title: title,
                     vms: vms,
                     store: devices,
                     routing: routing,
                     scanner: scanner,
                     logging: logging
        )
    }

    func makePastSessionsVM() -> HistoricalSessionsVM {
        .init(sessionRepo: sessions, exportQueue: actionQueue, routing: routing)
    }

    // MARK: - Create Sensor Recording Options

    func makeConfigureVM() -> ConfigureVM {
        guard let focus = routing.focus else { fatalError("Set focus before navigation") }
        let (title, metawears) = getKnownDevices(for: focus.item)
        return .init(title: title, item: focus.item, devices: metawears, presets: presets, routing: routing)
    }

    // MARK: - Perform Log/Download/Stream

    func makeActionVM() -> ActionVM {
        guard let focus = routing.focus else { fatalError("Set focus before navigation") }
        let action = ActionType(destination: routing.destination)
        let date = logging.session(for: focus.item)?.date ?? Date()
        let (_, metawears) = getKnownDevices(for: focus.item)
        let vms = makeAboutVMs(for: metawears)
        return .init(action: action,
                     name: focus.sessionNickname,
                     date: date,
                     devices: metawears,
                     vms: vms,
                     store: devices,
                     sessions: sessions,
                     routing: routing,
                     logging: logging,
                     backgroundQueue: actionQueue
        )
    }

}

private extension UIFactory {

    private func makeAboutVMs(for devices: [MWKnownDevice]) -> [AboutDeviceVM] {
        let vms = devices.map(makeAboutDeviceVM(device:))
        vms.indices.forEach { vms[$0].configure(for: $0) }
        return vms
    }

    private func getKnownDevices(for item: Routing.Item) -> (title: String, devices: [MWKnownDevice]) {
        switch item {
            case .group(let id):
                guard let group = devices.getGroup(id: id) else { break }
                return (group.name, devices.getDevicesInGroup(group))

            case .known(let mac):
                guard let device = devices.getDeviceAndMetadata(mac) else { break }
                return (device.meta.name, [device])
        }
        return (title: "Error", devices: [])
    }

    private func _makeBackgroundQueue(named: String) -> DispatchQueue {
        DispatchQueue(
            label: Bundle.main.bundleIdentifier! + ".\(named)",
            qos: .userInitiated,
            attributes: .concurrent
        )
    }
}
