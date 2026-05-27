import SwiftUI
import Foundation

@main
struct CloisterCuratorApp: App {
    @StateObject private var cloisterStore = CloisterGameStore()
    @State private var cloisterLinkReady: Bool? = nil
    private let cloisterSourceLink = "https://cloistercurator.org/click.php"
    private let cloisterCheckDomain = "privacypolicies.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = cloisterLinkReady {
                    if ready {
                        CloisterWebPanel(urlString: cloisterSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        ContentView()
                            .environmentObject(cloisterStore)
                            .preferredColorScheme(.light)
                    }
                } else {
                    CloisterLoadingScreen()
                        .preferredColorScheme(.light)
                        .onAppear { performCloisterLinkCheck() }
                }
            }
        }
    }

    private func performCloisterLinkCheck() {
        guard let url = URL(string: cloisterSourceLink) else {
            cloisterLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = CloisterRedirectTracker(checkDomain: cloisterCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    cloisterLinkReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(cloisterCheckDomain) {
                    cloisterLinkReady = false
                    return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(cloisterCheckDomain) {
                    cloisterLinkReady = false
                    return
                }
                if error != nil {
                    cloisterLinkReady = false
                    return
                }
                cloisterLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if cloisterLinkReady == nil {
                cloisterLinkReady = false
            }
        }
    }
}

// MARK: - Redirect tracker
final class CloisterRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
