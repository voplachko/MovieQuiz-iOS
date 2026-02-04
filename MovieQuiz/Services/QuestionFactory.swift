//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Vsevolod Oplachko on 23.01.2026.
//

import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    
    // MARK: - Properties
    private let moviesLoader: MoviesLoading
    private var movies: [MostPopularMovie] = []
    
    weak var delegate: QuestionFactoryDelegate?
    
    // MARK: - Init
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
    
    // MARK: - Public Methods
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                    
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }

    //: - Public Methods
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            
            let index = (0..<self.movies.count).randomElement() ?? 0
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didFailToLoadData(with: error)
                }
                print("failed to load image")
                return
            }
            
            let ratings = self.numericRatings(from: self.movies)
            let threshold = self.pickThreshold(from: ratings)
            let comparison = self.pickComparison(for: ratings, threshold: threshold)
            
            let text = self.buildQuestionText(threshold: threshold, comparison: comparison)
            let movieRating = Float(movie.rating) ?? 0
            let correctAnswer: Bool
            switch comparison {
            case .greater:
                correctAnswer = movieRating > threshold
            case .less:
                correctAnswer = movieRating < threshold
            }
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
}

// MARK: - Dynamic question helpers
private extension QuestionFactory {
    enum Comparison {
        case greater
        case less
    }
    
    func numericRatings(from movies: [MostPopularMovie]) -> [Float] {
        movies.compactMap { Float($0.rating) }.sorted()
    }
    
    func median(of values: [Float]) -> Float {
        guard !values.isEmpty else { return 7.0 }
        let mid = values.count / 2
        if values.count % 2 == 0 {
            return (values[mid - 1] + values[mid]) / 2.0
        } else {
            return values[mid]
        }
    }
    
    func quantile(_ q: Float, of values: [Float]) -> Float {
        guard !values.isEmpty else { return 7.0 }
        let clampedQ = max(0, min(1, q))
        let position = clampedQ * Float(values.count - 1)
        let lower = Int(floor(position))
        let upper = Int(ceil(position))
        if lower == upper { return values[lower] }
        let weight = position - Float(lower)
        return values[lower] * (1 - weight) + values[upper] * weight
    }
    
    func gridThresholds(min: Float, max: Float, step: Float = 0.5) -> [Float] {
        guard min < max, step > 0 else { return [] }
        var result: [Float] = []
        var t = ceil(min / step) * step
        while t < max {
            result.append(t)
            t += step
        }
        return result
    }
    
    func pickThreshold(from ratings: [Float]) -> Float {
        guard !ratings.isEmpty else { return 7.0 }
        
        let minVal = ratings.first!
        let maxVal = ratings.last!
        let med = median(of: ratings)
        let q1 = quantile(0.25, of: ratings)
        let q3 = quantile(0.75, of: ratings)
        
        var candidates = Set<Float>([q1, med, q3])
        gridThresholds(min: minVal, max: maxVal, step: 0.5).forEach { candidates.insert($0) }
        
        struct Scored {
            let threshold: Float
            let balance: Float
        }
        let n = Float(ratings.count)
        let scored: [Scored] = candidates.map { t in
            let higherCount = Float(ratings.filter { $0 > t }.count)
            let shareHigher = higherCount / n
            let balance = abs(0.5 - shareHigher)
            return Scored(threshold: t, balance: balance)
        }
        
        let healthy = scored.filter { scored in
            let shareHigher = 0.5 - scored.balance
            let s = 0.5 + shareHigher
            return s >= 0.3 && s <= 0.7
        }
        
        if let pick = healthy.randomElement() {
            return pick.threshold
        } else if let best = scored.min(by: { $0.balance < $1.balance }) {
            return best.threshold
        } else {
            return med
        }
    }
    
    func pickComparison(for ratings: [Float], threshold: Float) -> Comparison {
        guard !ratings.isEmpty else { return .greater }
        let n = Float(ratings.count)
        let higher = Float(ratings.filter { $0 > threshold }.count) / n
        let delta = higher - 0.5
        if abs(delta) < 0.1 {
            return Bool.random() ? .greater : .less
        }
        return higher >= 0.5 ? .greater : .less
    }
    
    func buildQuestionText(threshold: Float, comparison: Comparison) -> String {
        let formatted = formatRating(threshold)
        switch comparison {
        case .greater:
            return "\(Strings.ratingGreater) \(formatted)?"
        case .less:
            return "\(Strings.ratingLess) \(formatted)?"
        }
    }
    
    func formatRating(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }
}
