//
//  QuestionFactoryProtocol.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 23.01.2026.
//

import Foundation

protocol QuestionFactoryProtocol: AnyObject {
//    var delegate: QuestionFactoryDelegate? { get set }
    func requestNextQuestion()
}
