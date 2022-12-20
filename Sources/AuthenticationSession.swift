import AuthenticationServices
import SafariServices

protocol AuthenticationSession {
    typealias CompletionHandler = (Result<URL, Error>) -> Void
    @discardableResult func start() -> Bool
    func cancel()
}

extension SFAuthenticationSession: AuthenticationSession {}

@available(iOS 12.0, *)
extension ASWebAuthenticationSession: AuthenticationSession {}

class AuthenticationSessionProvider: NSObject {
    func makeAuthenticationSession(
        url: URL,
        redirectURI: String,
        prefersEphemeralWebBrowserSession: Bool?,
        completionHandler: @escaping AuthenticationSession.CompletionHandler
    ) -> AuthenticationSession {
        let handler: (URL?, Error?) -> Void = { (url: URL?, error: Error?) in
            if let error = error {
                return completionHandler(.failure(wrapError(error: error)))
            }

            if let url = url {
                return completionHandler(.success(url))
            }
        }

        if #available(iOS 12.0, *) {
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: getURIScheme(uri: redirectURI),
                completionHandler: handler
            )

            if #available(iOS 13.0, *) {
                session.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession ?? false
                session.presentationContextProvider = self
            }

            return session
        } else {
            let session = SFAuthenticationSession(
                url: url,
                callbackURLScheme: getURIScheme(uri: redirectURI),
                completionHandler: handler
            )
            return session
        }
    }

    private func getURIScheme(uri: String) -> String {
        if let index = uri.firstIndex(of: ":") {
            return String(uri[..<index])
        }
        return uri
    }
}

extension AuthenticationSessionProvider: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 13.0, *)
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.windows.filter { $0.isKeyWindow }.first!
    }
}
