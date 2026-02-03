import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var correctAnswers = 0
    
    private let presenter = MovieQuizPresenter()
    private var questionFactory: QuestionFactoryProtocol?
    private var alertPresenter = AlertPresenter()
    private var statisticService: StatisticServiceProtocol!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureServices()
        startGame()
        
        presenter.viewController = self
    }
    
    // MARK: - Setup
    private func configureUI() {
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
    }
    
    private func configureServices() {
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticService()
    }
    
    private func startGame() {
        setButtonsEnabled(false)
        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didReceiveNextQuestion(question: question)
    }
    
    func didLoadDataFromServer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hideLoadingIndicator()
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    func didFailToLoadData(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.presenter.isShowingError = true
            self.showNetworkError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Actions
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        presenter.yesButtonClicked()
    }
    
    // MARK: - UI helpers
    func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
        
        imageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func showAnswerResult(isCorrect: Bool) {
        setButtonsEnabled(false)
        
        if isCorrect { correctAnswers += 1 }
        
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.presenter.correctAnswers = self.correctAnswers
            self.presenter.questionFactory = self.questionFactory
            self.presenter.showNextQuestionOrResults()
            self.setButtonsEnabled(true)
        }
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let bestGame = statisticService.bestGame

        statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)

        let message =
        """
        \(result.text)
        \(Strings.quizzesCount) \(statisticService.gamesCount)
        \(Strings.record) \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
        \(Strings.averageAccuracy) \(String(format: "%.2f", statisticService.totalAccuracy))%
        """

        let model = AlertModel(
            title: result.title,
            message: message,
            buttonText: result.buttonText,
            accessibilityIdentifier: "Game results",
            completion: { [weak self] in
                guard let self else { return }

                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                self.setButtonsEnabled(false)
                self.showLoadingIndicator()
                self.questionFactory?.requestNextQuestion()
            }
        )

        alertPresenter.show(in: self, model: model)
    }
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    func setButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        setButtonsEnabled(false)
        
        guard isViewLoaded, view.window != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.showNetworkError(message: message)
            }
            return
        }
        
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            guard let self else { return }
            self.presenter.isShowingError = false
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            self.setButtonsEnabled(false)
            self.showLoadingIndicator()
            self.questionFactory?.loadData()
        }
        
        alertPresenter.show(in: self, model: model)
    }
}

