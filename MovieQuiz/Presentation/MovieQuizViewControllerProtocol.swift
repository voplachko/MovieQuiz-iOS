//
//  MovieQuizViewControllerProtocol.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 03.02.2026.
//

import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    
    func highlightImageBorder(isCorrectAnswer: Bool)
    
    func showLoadingIndicator()
    func hideLoadingIndicator()
    
    func setButtonsEnabled(_ isEnabled: Bool)
    
    func showNetworkError(message: String)
}
