import KituraSession

final class CheckoutSession: TypeSafeSession {
    let sessionId: String                       // Requirement: every session must have an ID
    var setNames: [SetName]
    var problems: [Problem]

    init(sessionId: String) {                   // Requirement: must be able to create a new (empty)
        self.sessionId = sessionId              // session containing just an ID. Assign a default or
        setNames = []
        problems = []                            // empty value for any non-optional properties.
    }
}

// Defines the configuration of the user's type: how the cookie is constructed and how
// the session is persisted.
extension CheckoutSession {
    static let sessionCookie: SessionCookie = SessionCookie(name: "MySession", secret: "Top Secret")
    static var store: Store?
}