//
//  GoogleSignInManager.swift
//  MusicApp
//
//  Created by 김정은 on 6/5/25.
//

import FirebaseCore
import GoogleSignIn
import FirebaseAuth

class GoogleSignInManager {
    static let shared = GoogleSignInManager()

    private init() {}

    // Google Sign-In 의 GIDSignIn configureation 할당
    func configure() {
        // Firebase 앱의 구성 옵션에서 클라이언트 ID를 가져온다. 이 클라이언트 ID는 Google Sign-In에 필요한 구성 정보
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // 위에서 가져온 클라이언트 ID를 사용하여 GIDConfiguration 객체를 생성,이 객체는 Google Sign-In 프로세스의 구성을 나타냄
        let config = GIDConfiguration(clientID: clientID)

        // GIDSignIn 공유 인스턴스에 위에서 생성한 config를 할당
        GIDSignIn.sharedInstance.configuration = config
    }

    func signIn(from viewController: UIViewController, completion: @escaping (AuthCredential?, Error?) -> Void) {

        // signIn 메서드를 호출하여 로그인 프로세스 시작.
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                guard error == nil,
                      let user = result?.user,
                      let idToken = user.idToken?.tokenString
                else {
                    completion(nil, error)
                    return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                completion(credential, nil)
            }
        }
}
