//
//  AlertPresenter.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 26.01.2026.
//

import Foundation
import UIKit

final class AlertPresenter {
    func show(in vc: UIViewController, model: AlertModel) {
        DispatchQueue.main.async {
            guard vc.presentedViewController == nil else { return }
            
            let alert = UIAlertController(
                title: model.title,
                message: model.message,
                preferredStyle: .alert
            )
            
            let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
                model.completion()
            }
            
            alert.addAction(action)
            vc.present(alert, animated: true)
        }
    }
}


