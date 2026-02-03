//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 03.02.2026.
//

import Foundation

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private let statisticService: StatisticServiceProtocol!
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewControllerProtocol?
    
    private var currentQuestion: QuizQuestion?
    private let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0
        
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        
        statisticService = StatisticService()
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    func noButtonClicked() {
        answerCurrentQuestion(with: false)
    }
    
    func yesButtonClicked() {
        answerCurrentQuestion(with: true)
    }
    
    private func answerCurrentQuestion(with answer: Bool) {
        guard let currentQuestion else { return }
        showAnswerResult(isCorrect: answer == currentQuestion.correctAnswer)
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
        
    func didAnswer(isCorrectAnswer: Bool) {
        if isCorrectAnswer {
            correctAnswers += 1
        }
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        
        currentQuestion = question
        
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.viewController?.hideLoadingIndicator()
            self.viewController?.setButtonsEnabled(true)
            self.viewController?.show(quiz: viewModel)
        }
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: model.image,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            let text = "Ваш результат: \(self.correctAnswers)/\(self.questionsAmount)"
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз"
            )
            viewController?.show(quiz: viewModel)
        } else {
            self.switchToNextQuestion()
            self.viewController?.setButtonsEnabled(false)
            self.viewController?.showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }
    
    func makeResultsMessage() -> String {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let bestGame = statisticService.bestGame
        
        let totalPlaysCountLine = "\(Strings.quizzesCount) \(statisticService.gamesCount)"
        let currentGameResultLine = "\(Strings.yourResult) \(correctAnswers)\\\(questionsAmount)"
        let bestGameInfoLine = "\(Strings.record) \(bestGame.correct)\\\(bestGame.total) (\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "\(Strings.averageAccuracy) \(String(format: "%.2f", statisticService.totalAccuracy))%"
        
        return [
            currentGameResultLine,
            totalPlaysCountLine,
            bestGameInfoLine,
            averageAccuracyLine
        ].joined(separator: "\n")
    }
    
    func showAnswerResult(isCorrect: Bool) {
        didAnswer(isCorrectAnswer: isCorrect)
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
}
