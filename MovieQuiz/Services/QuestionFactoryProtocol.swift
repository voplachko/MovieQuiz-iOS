//
//  QuestionFactoryProtocol.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 23.01.2026.
//

import Foundation

protocol QuestionFactoryProtocol: AnyObject {
    func requestNextQuestion()
    func loadData()
}
