//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 03.02.2026.
//

import Foundation

final class MovieQuizPresenter {
    
    let questionsAmount: Int = 10
    
    var correctAnswers: Int = 0
    var currentQuestion: QuizQuestion?
    var isShowingError = false
    var questionFactory: QuestionFactoryProtocol?
    
    weak var viewController: MovieQuizViewController?
    
    private var currentQuestionIndex: Int = 0
    
    func noButtonClicked() {
        answerCurrentQuestion(with: false)
    }
    
    func yesButtonClicked() {
        answerCurrentQuestion(with: true)
    }
    
    private func answerCurrentQuestion(with answer: Bool) {
        guard let currentQuestion else { return }
        viewController?.showAnswerResult(isCorrect: answer == currentQuestion.correctAnswer)
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
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
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        guard !isShowingError else { return }
        
        currentQuestion = question
        
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.isShowingError else { return }
            self.viewController?.hideLoadingIndicator()
            self.viewController?.setButtonsEnabled(true)
            self.viewController?.show(quiz: viewModel)
        }
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
}
