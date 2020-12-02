# Swift Vapor お問い合わせフォーム

<img width="600" alt="image" src="/Images/social-image.png?raw=true">

**Swift + Vapor + Leaf + Github Oauth + captcha + メールAPI**

多くの個人開発者のウェブサイトを見てみたところ、すべてにコンタクトフォームがあることが分かりました。​私のサイトにはまだコンタクトフォームがなかったので、Swift Vaporを実装したのです。

これは、`Swift Vapor`で開発されたウェブサイトのお問い合わせフォームです。従来のお問い合わせフォームとは異なり、これはメールアドレスが確かにユーザーのものであることを確認（スパムの防止）するためにユーザーにGithubでサインインするよう求め、そして`hCaptcha`を使ってフォームに入力しているのがボットではなく人間であることを検証します。

私はSwiftの経験はありますが、これは私にとってSwiftでサーバーを実行する最初の数少ないプロジェクトの1つです。遠慮なくこのリポジトリに新しい機能を提案/追加してください。

[機能](#機能)

[スクリーンショット](#スクリーンショット)

[Contribution](#Contribution)

[関数](#関数)

[`Vapor` とは](#vapor-とは)

[ `Vapor` をインストールしてスタータープロジェクトを設定](#vapor-をインストールしてスタータープロジェクトを設定)

[アプリケーションをUbuntuに展開します (Swift + Vapor + Nginx](#アプリケーションをubuntuに展開します)

## 機能

- `Github.com`アカウントでログイン
- アプリが`Github.com`プロフィールと関連付いたメールアドレスをフェッチします。
- 次にユーザーはフォーム内のメールアドレスの1つを選択し、連絡フォームで名前とコンテンツを入力できます。
- 次にユーザーは`hCaptcha`によって提供されたキャプチャを検証してから、フォームを送信します。
- フォームで送信されたコンテンツは`Mailgun API`を使い、`APICredentials.swift` ファイル内で定義されたメールアドレス宛にメール送信されます。

## スクリーンショット

​ホーム画面のビューはこちらです：
​
​![image](/Images/HomePage.png)

​フォームのビューはこちらです：
​
​​![image](/Images/ContactForm.png)

## コンフィギュレーション

[`APICredentials.swift`](https://github.com/mszmagic/SwiftVapor-Contact-Form/blob/master/Sources/App/APICredentials.swift)を更新して、GithubアプリケーションクライアントID/シークレット（ユーザーの認証用）、`Mailgun`API（メールの送信用）、`hCaptcha`アプリID/シークレット（ユーザーにCAPTCHAの検証を依頼するため）を提供する必要があります。

## Contribution

I would be happy if you want to contribute to this repository. Please create Github issues or pull requests. こちらでは投稿を歓迎しています！お気軽にイシューやプルリクエストを開始してください。

## 関数

### `RequestController.swift`

このファイルには、外部ネットワークへのAPIリクエストを発行する関数を収めています。3つの関数からなります。

- `Github API`をコールし、ログインコードを使用してOauth認証トークンを取得する
- `Github API`をコールし、Oauth認証トークンを使用してユーザの電子メールアドレスのリストを取得する
- `hcaptcha`のAPIをコールし、captchaが正常に完了したか確認する
- `Mailgun`のAPIをコールし、電子メールを送信する

### `APICredentials.swift`

このファイルには以下の3つのサービス用のAPIトークンが含まれます：`Github`、`hCaptcha`、`Mailgun`。また、通知用コンタクトフォームの送信者のメールアドレス（お使いのドメインのいづれかのメールアドレス）と受取人のメールアドレスも含まれます。

### `configure.swift`

`Vapor` の構成ファイル。

### `routes.swift`

このファイルの構成されたネットワークルートはこちら:

```swift
/**
 `Leaf`によってレンダリングされたホームページ
 ファイルは`/Resources/Views/index.leaf`に配置されています
 */
app.get
```

```swift
/**
 ユーザをGithubのサインインページへリダイレクトすることのより、Github認証のフローを開始します。
 
 - 設定済みリダイレクトURL（サインイン成功時）は`github_callback`に設定されています
 */
app.get("start")
```

```swift
/**
 一度サインインに成功し、サインインコードが取得できていれば、APIをコールすることによってOauthトークンの取得を試みてください（関数は`RequestController`で定義されています）
 - ユーザがサインインに成功したとき、Githubはこのエンドポイントをコールします。

 - `https://[Your server name]/github_callback`をGithubアプリのユーザ認証コールバックURL `User authorization callback URL` に設定しておく必要があります。
 */
app.get("github_callback")
```

```swift
/**
 ユーザーの認証後、HTMLテンプレートファイルの`form.leaf`をレンダリングしてフォームを表示します
 - メールアドレスがセッションストレージに保存されているか照合することで、ユーザーが実際にサインインしているかどうかを確認することになります。
 */
app.get("form")
```

```swift
/**
 ユーザーが送信ボタンをクリックすると、フォームがこのAPIに対するPOSTリクエストを作成します。リクエストには名前、メールアドレス、キャプチャ検証コードが含まれます。
 - メールアドレスの有効性をもう一度検証します
 - キャプチャ検証コードが有効かどうかチェックします。
 */
app.post("submit")
```

## `Vapor` とは

`Vapor` は Swift 言語を使ってウェブサーバーを構築できるようにするフレームワークです。Macにサーバーを開発し、Ubuntuシステムにサーバーをデプロイすることができます。


`Vapor` は動的に生成されたHTMLコンテンツをSwiftコードでレンダリングできるようにするとともに、ご自分のAPIを（入力に基づいてさまざまな応答を提供することにより）ホストできるようにします。

概して言うと、すでにモバイル開発用のSwiftをお使いであれば、サーバーおよびアプリケーション開発に対するSwift + Vaporの実用性をご理解いただける可能性があります。


## `Vapor` をインストールしてスタータープロジェクトを設定

`Vapor` を Mac にインストールするには、これらのコマンドをターミナルで実行することができます。

```shell
brew tap vapor/tap
brew install vapor/tap/vapor
git clone https://github.com/mszmagic/SwiftVapor-Contact-Form.git
cd SwiftVapor-Contact-Form
vapor xcode
// vapor run
```

## アプリケーションをUbuntuに展開します

### Swiftをインストールします

最新のSwiftバージョンのダウンロード用のリンクはこちらから取得できます : https://swift.org/download/#releases

```bash
sudo apt-get install clang

wget https://swift.org/builds/swift-5.3.1-release/ubuntu2004/swift-5.3.1-RELEASE/swift-5.3.1-RELEASE-ubuntu20.04.tar.gz

tar xzf swift-5.3.1-RELEASE-ubuntu20.04.tar.gz

rm swift-5.3.1-RELEASE-ubuntu20.04.tar.gz

sudo mv swift-5.3.1-RELEASE-ubuntu20.04 /usr/share/swift

echo "export PATH=/usr/share/swift/usr/bin:$PATH" >> ~/.bashrc

source  ~/.bashrc
```

それからコマンドを実行することでテストをインストールできます。

```shell
swift --version
```

### Vapor toolbox をインストールします

```shell

apt-get install -y zlib1g-dev

git clone https://github.com/vapor/toolbox vapor-toolbox

cd vapor-toolbox

cd Tests

touch LinuxMain.swift

cd ../

swift build -c release --disable-sandbox

mv .build/release/vapor /usr/local/bin
```

### サーバー ファイルを複製します。

Mac 上のファイルをリモート Git サーバーにプッシュし、これらのコードを Linux サーバーのディレクトリにプルできます。この例では、コードを `/home/ubuntu/feedbackform` に複製できます。

以下のコマンドを実行して、レポジトリを複製し、サーバーを構築します。

```
cd /home/ubuntu
git clone ...
cd feedbackform
vapor build
```

また、`supervisor`アプリケーションがサーバーを素早く構築して起動できるように、`run.sh`ファイルを作成することもできます。

```shell
nano run.sh

#!/bin/bash
swift build --configuration release
.build/release/Run serve --env production --port 8080 --hostname 0.0.0.0
```

加えて、`Tests`ディレクトリーに空の`LinuxMain.swift`ファイルを作成する必要もあります。

```shell
cd Tests
touch LinuxMain.swift
```

### Vaporサーバーの起動

`./run.sh`を実行することで、Vaporサーバーを起動できます。

また、`supervisor`を使ってサーバーが自動的に実行されるように設定することもできます。

```shell
apt install supervisor

nano /etc/supervisor/conf.d/vapor_server.conf
```

`vapor_server.conf`ファイルに以下の内容を入力してください

```
[program:app_collection]
command=/home/ubuntu/feedbackform/run.sh
directory=/home/ubuntu/feedbackform
autorestart=true
user=ubuntu
```

```shell
supervisorctl reread
supervisorctl update
```

これで、ポート8080上でVaporサーバーが起動しているはずです。次に、そのポートをポート80またはポート443にプロキシ接続するために、プロキシを使う必要があります。

また、`supervisor`を使うことで、Linuxシステムが起動する度にVaporサーバーを立ち上げさせることができます。

### Nginxプロキシサーバーの設定

まず、Nginxをインストールする必要があります

```shell
sudo apt update
sudo apt install nginx
```

その後、Nginxのデフォルト設定ファイルを編集できます。

```shell
cd /etc/nginx/sites-enabled/
nano default
```

`default`ファイルの内容がこちらです。

```
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        proxy_pass http://localhost:8080;
    }
}
```

これで、`Nginx`サーバーを再読み込みする準備が整いました。

```
sudo service nginx restart
```

### HTTPSの設定

これで、`LetsEncrypt`を使ってサーバーのHTTPSを設定する準備が整いました。Nginxサーバーをプロキシとして設定したので、`DNS`を用いてドメインの所有権を検証して、手動で`Nginx`の設定ファイルを編集する方が楽かもしれません。

```shell
sudo apt-get update
sudo apt-get install python3-certbot-nginx
sudo certbot -d [Your domain] --manual --preferred-challenges dns certonly
```

その後、`/etc/nginx/sites-enabled/default` ファイルを編集することができます :

```
ssl_certificate /etc/letsencrypt/live/[Domain name]/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/[Domain name]/privkey.pem;
```

更新されたNginx構成はこのように表示されます

```
server {
    listen 443 ssl;

    ssl_certificate /etc/letsencrypt/live/[Domain name]/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/[Domain name]/privkey.pem;
    ssl_protocols TLSv1.2;

    location / {
        proxy_pass http://localhost:8080;
    }
}
```

これで、`Nginx`サーバーを再読み込みする準備が整いました。

```
sudo service nginx restart
```
