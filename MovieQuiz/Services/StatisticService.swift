//
//  StatisticService.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 27.01.2026.
//

import Foundation

final class StatisticService {
    private let storage: UserDefaults = .standard
    
    private enum Keys: String {
        case gamesCount = "gamesCount"
        case bestGameCorrect = "bestGameCorrect"
        case bestGameTotal = "bestGameTotal"
        case bestGameDate = "bestGameDate"
        case totalCorrectAnswers = "totalCorrectAnswers"
        case totalQuestionsAsked = "totalQuestionsAsked"
    }
    
    private var totalCorrectAnswers: Int {
        get {
            storage.integer(forKey: Keys.totalCorrectAnswers.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.totalCorrectAnswers.rawValue)
        }
    }
    
    private var totalQuestionsAsked: Int {
        get {
            storage.integer(forKey: Keys.totalQuestionsAsked.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.totalQuestionsAsked.rawValue)
        }
    }
}

extension StatisticService: StatisticServiceProtocol {
    var totalAccuracy: Double {
        let questions = totalQuestionsAsked
        guard questions > 0 else { return 0 }
        return Double(totalCorrectAnswers) / Double(questions) * 100
    }
    
    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            storage.set(newValue, forKey:Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameResult {
        get {
            let correct = storage.integer(forKey: Keys.bestGameCorrect.rawValue)
            let total = storage.integer(forKey: Keys.bestGameTotal.rawValue)
            let date = storage.object(forKey: Keys.bestGameDate.rawValue) as? Date ?? Date()
            
            return GameResult(
                correct: correct,
                total: total,
                date: date
            )
        }
        set {
            storage.set(newValue.correct, forKey: Keys.bestGameCorrect.rawValue)
            storage.set(newValue.total, forKey: Keys.bestGameTotal.rawValue)
            storage.set(newValue.date, forKey: Keys.bestGameDate.rawValue)
        }
    }
    
    func store(correct count: Int, total amount: Int) {
        totalCorrectAnswers += count
        totalQuestionsAsked += amount
        
        gamesCount += 1

        let currentGame = GameResult(
            correct: count,
            total: amount,
            date: Date()
        )
        
        if currentGame.isBetterThan(bestGame) {
            bestGame = currentGame
        }
    }
}
