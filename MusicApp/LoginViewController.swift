//
//  LoginViewController.swift
//  MusicApp
//
//  Created by 김정은 on 6/5/25.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import FirebaseAuth


class LoginViewController: UIViewController {
    
    @IBOutlet weak var googleButton: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        GoogleSignInManager.shared.configure()
        
        // 제스처 인식기 설정
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGoogleButtonTap))
        googleButton.isUserInteractionEnabled = true
        googleButton.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleGoogleButtonTap() {
        GoogleSignInManager.shared.signIn(from: self) { credential, error in
            guard let credential = credential else {
                print("🔴 로그인 실패: \(error?.localizedDescription ?? "알 수 없음")")
                return
            }

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("🔴 Firebase 로그인 실패: \(error.localizedDescription)")
                    return
                }

                // ✅ 로그인 성공 → TabBarController로 전환
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = windowScene.delegate as? SceneDelegate {

                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
                        sceneDelegate.window?.rootViewController = tabBarController
                        sceneDelegate.window?.makeKeyAndVisible()
                    }
                }
            }
        }
    }

}
