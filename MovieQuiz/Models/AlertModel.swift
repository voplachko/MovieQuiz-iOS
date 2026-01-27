//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 26.01.2026.
//

import Foundation

struct AlertModel {
    var title: String
    var message: String
    var buttonText: String
    var completion: () -> Void
}
