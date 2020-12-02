//
//  File.swift
//  
//
//  Created by Shunzhe Ma on R 2/11/30.
//

import Foundation

class APICredentials {
    
    /* Github */
    //https://github.com/settings/apps
    static let github_client_id: String = <#key#>
    static let github_client_secret: String = <#key#>
    
    /* MailGun */
    //https://www.mailgun.com
    static let mailgun_sending_key: String = <#key#>
    static let receiver_email: String = <# メールアドレス #>
    static let sender_email: String = <# contact-form@[あなたのドメイン #>
    
    /* hCaptcha */
    //https://www.hcaptcha.com
    static let hcaptcha_site_key: String = <#key#>
    static let hcaptcha_secret_key: String = <#key#>
    
}
