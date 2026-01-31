//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 26.01.2026.
//

import Foundation

protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
}
