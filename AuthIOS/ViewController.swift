//
//  ViewController.swift
//  AuthIOS
//
//  Created by Michael Avoyan on 12/06/2022.
//

import UIKit
import VCLAuth

class ViewController: UIViewController {
    
    @IBOutlet weak var btnAuthenticate: UIButton!
    @IBOutlet weak var btnOpenSecuritySettings: UIButton!
    
    private var vclAuth: VCLAuth!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.vclAuth = VclAuthProvider.instance()
        
        btnAuthenticate.addTarget(self, action: #selector(authenticate), for: .touchUpInside)
        btnOpenSecuritySettings.addTarget(self, action: #selector(openSecuritySettings), for: .touchUpInside)
    }
    
    @objc private func authenticate() {
        vclAuth.isAuthenticationAvailable(
            successHandler: { [weak self] isAuthenticationAvailable in
                NSLog("VCL isAuthenticationAvailable: \(isAuthenticationAvailable)")
                if isAuthenticationAvailable {
                    self?.vclAuth.authenticate(
                        authConfig: VCLAuthConfig(
                            title: "The passcode you use to unlock this Phone, can also be used to access your Velocity account."
                        ),
                        successHandler: { isRecognized in
                            NSLog("VCL User recognized: \(isRecognized)")
                            
                        },
                        errorHandler: { [weak self] error in
                            NSLog("VCL Auth error: \(error)")
                            self?.showAlert(title: "Auth error", message: error.description)
                        })
                } else {
                    self?.showAlert(title: "Authentication is NOT Available", message: "")
                }
            },
            errorHandler: { [weak self] error in
                NSLog("VCL isAuthenticationAvailable error: \(error)")
                self?.showAlert(title: "isAuthenticationAvailable error", message: error.description)
            })
    }
    
    @objc private func openSecuritySettings() {
        vclAuth.openSecuritySettings (
            successHandler: { isOpen in
                NSLog("VCL Security settings open: \(isOpen)")
            },
            errorHandler: { error in
                NSLog("VCL Security settings open error: \(error)")
            })
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                alert.dismiss(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

