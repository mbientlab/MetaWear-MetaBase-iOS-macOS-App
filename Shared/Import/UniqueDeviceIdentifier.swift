// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

#if os(macOS)
import SystemConfiguration
/// Good-enough ID for a Mac, although users can change ethernet MAC addresses.
func getUniqueDeviceIdentifier() -> String {
    (SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? [])
        .map(SCNetworkInterfaceGetHardwareAddressString)
        .compactMap { $0 as String? }
        .sorted()
        .joined(separator: "")
}
#else
import UIKit
/// Crashes if used in background when device is not unlocked.
func getUniqueDeviceIdentifier() -> String {
    UIDevice.current.identifierForVendor!.uuidString
}
#endif
