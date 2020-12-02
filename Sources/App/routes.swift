import Vapor

struct FeedbackRequest: Content {
    var name: String
    var email: String
    var content: String
}

func routes(_ app: Application) throws {
    
    /**
     `Leaf`によってレンダリングされたホームページ
     ファイルは`/Resources/Views/index.leaf`に配置されています
     */
    app.get { request in
        return request.view.render("index")
    }

    /**
     ユーザをGithubのサインインページへリダイレクトすることのより、Github認証のフローを開始します。
     
     - 設定済みリダイレクトURL（サインイン成功時）は`github_callback`に設定されています
     */
    app.get("start") { request in
        return request.redirect(to: "https://github.com/login/oauth/authorize?client_id=\(APICredentials.github_client_id)")
    }
    
    /**
     一度サインインに成功し、サインインコードが取得できていれば、APIをコールすることによってOauthトークンの取得を試みてください（関数は`RequestController`で定義されています）
     - ユーザがサインインに成功したとき、Githubはこのエンドポイントをコールします。

     - `https://[Your server name]/github_callback`をGithubアプリのユーザ認証コールバックURL `User authorization callback URL` に設定しておく必要があります。
     */
    app.get("github_callback") { request -> EventLoopFuture<Response> in
        let promise = request.eventLoop.makePromise(of: Response.self)
        if let authCode = try? request.query.get(String.self, at: "code") {
            RequestController.shared.fetchToken(loginCode: authCode) { result in
                if let fetchedToken = result.code {
                    RequestController.shared.fetchEmailAddress(authToken: fetchedToken) { userEmails in
                        if userEmails.count > 0 {
                            request.session.data["github_email_addresses"] = userEmails.joined(separator: ",")
                            promise.succeed(request.redirect(to: "/form"))
                        } else {
                            promise.succeed(.failedObtainEmailFromGithub(version: request.version))
                        }
                    }
                } else {
                    let errorMessage = result.error ?? "不明なエラー"
                    promise.succeed(.generateResponse(text: errorMessage, status: .unauthorized, version: request.version))
                }
            }
        } else {
            promise.succeed(.failedObtainGithubAuthCode(version: request.version))
        }
        return promise.futureResult
    }
    
    /**
     ユーザーの認証後、HTMLテンプレートファイルの`form.leaf`をレンダリングしてフォームを表示します
     - メールアドレスがセッションストレージに保存されているか照合することで、ユーザーが実際にサインインしているかどうかを確認することになります。
     */
    app.get("form") { request -> EventLoopFuture<View> in
        if let emailAddressesString = request.session.data["github_email_addresses"] {
            // HTML形式でメールアドレスピッカー用の文字列を生成
            var formOptionString = ""
            let emailAddresses = emailAddressesString.split(separator: ",")
            for emailAddress in emailAddresses {
                formOptionString.append("<option>\(emailAddress)</option>")
            }
            return request.view.render("form", ["FormOptions": formOptionString, "hcaptcha_siteKey": APICredentials.hcaptcha_site_key])
        } else {
            return request.view.render("message", ["title": "無許可", "content": "セッションには有効なメールアドレスのリストが含まれていません。"])
        }
    }
    
    /**
     ユーザーが送信ボタンをクリックすると、フォームがこのAPIに対するPOSTリクエストを作成します。リクエストには名前、メールアドレス、キャプチャ検証コードが含まれます。
     - メールアドレスの有効性をもう一度検証します
     - キャプチャ検証コードが有効かどうかチェックします。
     */
    app.post("submit") { request -> EventLoopFuture<Response> in
        let promise = request.eventLoop.makePromise(of: Response.self)
        if let emailAddressesString = request.session.data["github_email_addresses"] {
            let feedback = try request.content.decode(FeedbackRequest.self)
            let captchaResponse = try request.content.get(String.self, at: "h-captcha-response")
            let emailAddresses = emailAddressesString.components(separatedBy: ",")
            if emailAddresses.contains(feedback.email) {
                // 有効な電子メール
                // Captcha:
                RequestController.shared.checkCaptcha(clientCaptchaResponse: captchaResponse) { captchaCorrect in
                    if captchaCorrect {
                        // 電子メールを送信する
                        RequestController.shared.sendEmail(fromEmail: APICredentials.sender_email,
                                                           fromName: "連絡フォーム",
                                                           toEmail: APICredentials.receiver_email,
                                                           title: "\(feedback.name)からのお問い合わせフォームの送信",
                                                           content: """
                            \(feedback.name)からメールアドレス \(feedback.email) を使って新しいお問い合わせフォームを送信しました。​内容は  \n\n \(feedback.content) \n\n です。​このメールに返信しないでください。​代わりに、上記のメールアドレスをクリックしてメールを送信してください。
                            """) { status in
                            if status == 200 {
                                promise.succeed(.generateResponse(text: "連絡フォームのデータが正常に転送されました！ \(feedback.name) \(feedback.email) \(feedback.content).", status: .ok, version: request.version))
                                // セッションストレージを消去する
                                request.session.data["github_email_addresses"] = ""
                            } else {
                                promise.succeed(.generateResponse(text: "申し訳ありません！連絡フォームのデータを転送する際にいくつかのエラーがあった疑いがあります。（サーバーから応答コード \(status) が報告されました。もう一度お試しください。 \(feedback.name) \(feedback.email) \(feedback.content).", status: .ok, version: request.version))
                            }
                        }
                    } else {
                        promise.succeed(.wrontCaptchaResponse(version: request.version))
                    }
                }
            } else {
                promise.succeed(.unverifiedEmailAddressResponse(version: request.version))
            }
        } else {
            promise.succeed(.noSessionInformationResponse(version: request.version))
        }
        return promise.futureResult
    }
    
}

extension Response {
    static func generateResponse(text: String, status: HTTPStatus, version: HTTPVersion) -> Response {
        return .init(status: status,
                     version: version,
                     headers: ["Content-Type": "text/html; charset=utf-8"
                     ],
                     body: .init(string: text))
    }
    static func failedObtainGithubAuthCode(version: HTTPVersion) -> Response {
        return Response.generateResponse(text: "Github認証コードの取得に失敗しました。", status: .unauthorized, version: version)
    }
    static func failedObtainEmailFromGithub(version: HTTPVersion) -> Response {
        return Response.generateResponse(text: "提供された認証トークンからのメールアドレスの取得に失敗しました。", status: .internalServerError, version: version)
    }
    static func unverifiedEmailAddressResponse(version: HTTPVersion) -> Response {
        return Response.generateResponse(text: "無効なメールアドレス。フォームに入力されているメールアドレスはあなたのGithubアカウントのものではありません。", status: .unauthorized, version: version)
    }
    static func noSessionInformationResponse(version: HTTPVersion) -> Response {
        return Response.generateResponse(text: "セッションストレージからメールアドレスを見つけることができません。", status: .unauthorized, version: version)
    }
    static func wrontCaptchaResponse(version: HTTPVersion) -> Response {
        return Response.generateResponse(text: "キャプチャ認証に失敗しました。ページをリロードしてキャプチャ認証を完了してください。", status: .unauthorized, version: version)
    }
}
