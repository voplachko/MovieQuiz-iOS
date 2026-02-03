//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 26.01.2026.
//

import Foundation

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
    let accessibilityIdentifier: String?

    init(
        title: String,
        message: String,
        buttonText: String,
        accessibilityIdentifier: String? = nil,
        completion: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.buttonText = buttonText
        self.accessibilityIdentifier = accessibilityIdentifier
        self.completion = completion
    }
}
