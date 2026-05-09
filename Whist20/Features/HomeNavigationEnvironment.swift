import SwiftUI

/// Gør det muligt at styre forsidenavigation (fx «Ny spilledag») fra underlag som «Alle spilledage».
struct HomeNavigationPathKey: EnvironmentKey {
    static var defaultValue: Binding<NavigationPath>? { nil }
}

extension EnvironmentValues {
    var homeNavigationPath: Binding<NavigationPath>? {
        get { self[HomeNavigationPathKey.self] }
        set { self[HomeNavigationPathKey.self] = newValue }
    }
}
