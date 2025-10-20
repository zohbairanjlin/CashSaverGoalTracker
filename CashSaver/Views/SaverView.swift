import SwiftUI
import WebKit

struct SaverViewRepresentable: UIViewRepresentable {
    let internetRequest: String
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        let saverView = WKWebView(frame: .zero, configuration: configuration)
        saverView.navigationDelegate = context.coordinator
        saverView.scrollView.contentInsetAdjustmentBehavior = .never
        saverView.scrollView.contentInset = .zero
        saverView.scrollView.scrollIndicatorInsets = .zero
        saverView.isOpaque = false
        saverView.backgroundColor = .clear
        saverView.scrollView.backgroundColor = .clear
        
        if let requestAddress = URL(string: internetRequest) {
            let request = URLRequest(url: requestAddress)
            saverView.load(request)
        }
        
        return saverView
    }
    
    func updateUIView(_ saverView: WKWebView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SaverViewRepresentable
        var isInitialLoad = true
        
        init(_ parent: SaverViewRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if isInitialLoad {
                DispatchQueue.main.async {
                    self.parent.isLoading = true
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if isInitialLoad {
                isInitialLoad = false
                DispatchQueue.main.async {
                    self.parent.isLoading = false
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if isInitialLoad {
                isInitialLoad = false
                DispatchQueue.main.async {
                    self.parent.isLoading = false
                }
            }
        }
    }
}

struct SaverView: View {
    let internetRequest: String
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            SaverViewRepresentable(internetRequest: internetRequest, isLoading: $isLoading)
                .ignoresSafeArea(.all, edges: .all)
            
            if isLoading {
                Color.black
                    .ignoresSafeArea(.all, edges: .all)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .statusBar(hidden: true)
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            AppDelegate.orientationLock = .all
            updateOrientation()
        }
        .onDisappear {
            AppDelegate.orientationLock = .portrait
            updateOrientation()
        }
    }
    
    private func updateOrientation() {
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: AppDelegate.orientationLock))
        }
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
