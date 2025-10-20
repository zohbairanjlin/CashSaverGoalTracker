import SwiftUI

struct LaunchView: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var isCheckingServer = true
    @State private var showSaverView = false
    @State private var saverLink = ""
    
    var body: some View {
        Group {
            if isCheckingServer {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            } else if showSaverView {
                SaverView(internetRequest: saverLink)
            } else {
                MainTabView()
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.currentTheme.colorScheme)
            }
        }
        .onAppear {
            checkServerOrToken()
        }
    }
    
    private func checkServerOrToken() {
        if StorageManager.shared.hasToken() {
            if let link = StorageManager.shared.getLink() {
                saverLink = link
                showSaverView = true
                isCheckingServer = false
            } else {
                isCheckingServer = false
            }
        } else {
            NetworkManager.shared.checkServerRequest { success, token, link in
                if success, let token = token, let link = link {
                    StorageManager.shared.saveToken(token)
                    StorageManager.shared.saveLink(link)
                    saverLink = link
                    showSaverView = true
                }
                isCheckingServer = false
            }
        }
    }
}


