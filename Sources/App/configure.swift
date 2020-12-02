import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    app.views.use(.leaf)
    app.middleware.use(app.sessions.middleware)
    app.sessions.configuration.cookieName = "session_id"
    try routes(app)
}
