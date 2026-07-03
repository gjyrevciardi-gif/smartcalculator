//
//  CalculatorViewModel.swift
//  Calculator
//
//  Created by Ricardo Montemayor on 20/07/22.
//

import Foundation
import Combine

extension CalculatorView {
    final class ViewModel: ObservableObject {
        enum CalculatorMode: String, CaseIterable, Identifiable {
            case basic = "Basic"
            case scientific = "Scientific"
            case convert = "Convert"
            case mathNotes = "Math Notes"

            var id: String { rawValue }
        }

        enum ConversionCategory: String, CaseIterable, Identifiable {
            case length = "Length"
            case weight = "Weight"
            case temperature = "Temperature"

            var id: String { rawValue }
        }

        // MARK: - PROPERTIES

        @Published private var calculator = Calculator()
        @Published var mode: CalculatorMode = .basic
        @Published var showMarkupSettings: Bool = false
        @Published var showHistory: Bool = false
        @Published var markupPercent: String = "20"
        @Published var conversionCategory: ConversionCategory = .length
        @Published var conversionInput: String = "1"
        @Published var mathNoteText: String = "12 * (4 + 3) ="

        var displayText: String {
            return calculator.displayText
        }

        var expressionText: String {
            return calculator.expressionText
        }

        var history: [Calculator.HistoryEntry] {
            return calculator.history
        }

        var markupPercentLabel: String {
            return "\(markupPercentNumber.formatted(.number.precision(.fractionLength(0))))%"
        }

        var buttonTypes: [[ButtonType]] {
            let clearType: ButtonType = calculator.showAllClear ? .allClear : .clear
            return [
                scientificRow,
                [clearType, .backspace, .percent, .operation(.division)],
                [.digit(.seven), .digit(.eight), .digit(.nine), .operation(.multiplication)],
                [.digit(.four), .digit(.five), .digit(.six), .operation(.subtraction)],
                [.digit(.one), .digit(.two), .digit(.three), .operation(.addition)],
                [.digit(.zero), .decimal, .equals]
            ]
            .filter { !$0.isEmpty }
        }

        var conversionSourceUnit: String {
            switch conversionCategory {
            case .length:
                return "m"
            case .weight:
                return "kg"
            case .temperature:
                return "C"
            }
        }

        var conversionResult: String {
            let value = Double(conversionInput) ?? 0
            let converted: Double
            let unitText: String

            switch conversionCategory {
            case .length:
                converted = value * 3.28084
                unitText = "ft"
            case .weight:
                converted = value * 2.20462
                unitText = "lb"
            case .temperature:
                converted = (value * 9 / 5) + 32
                unitText = "F"
            }

            return "\(format(converted)) \(unitText)"
        }

        var mathNoteResult: String {
            let expression = mathNoteText
                .replacingOccurrences(of: "=", with: "")
                .replacingOccurrences(of: "x", with: "*")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !expression.isEmpty else { return "" }

            var evaluator = ExpressionEvaluator(expression: expression)
            guard let value = evaluator.evaluate() else {
                return ""
            }

            return format(value)
        }

        // MARK: - ACTIONS

        func performAction(for buttonType: ButtonType) {
            switch buttonType {
            case .digit(let digit):
                calculator.setDigit(digit)
            case .operation(let operation):
                calculator.setOperation(operation)
            case .scientific(let function):
                calculator.setScientificFunction(function)
            case .negative:
                calculator.toggleSign()
            case .percent:
                calculator.setPercent()
            case .decimal:
                calculator.setDecimal()
            case .equals:
                calculator.evaluate(markupPercent: markupPercentNumber)
            case .allClear:
                calculator.allClear()
            case .clear:
                calculator.clear()
            case .backspace:
                calculator.backspace()
            }
        }

        func clearHistory() {
            calculator.clearHistory()
        }

        // MARK: - HELPERS

        /// Checks if current buttonType of type .arithmeticOperation is active
        func buttonTypeIsHighlighted(buttonType: ButtonType) -> Bool {
            guard case .operation(let operation) = buttonType else { return false }
            return calculator.operationIsHighlighted(operation)
        }

        private var scientificRow: [ButtonType] {
            guard mode == .scientific else { return [] }
            return [.scientific(.sine), .scientific(.cosine), .scientific(.tangent), .scientific(.square)]
        }

        private var markupPercentNumber: Decimal {
            return Decimal(string: markupPercent) ?? 0
        }

        private func format(_ value: Double) -> String {
            return value.formatted(.number.precision(.fractionLength(0...8)))
        }
    }
}

private struct ExpressionEvaluator {
    private let expression: String
    private var index: String.Index

    init(expression: String) {
        self.expression = expression
        self.index = expression.startIndex
    }

    mutating func evaluate() -> Double? {
        guard let value = parseExpression() else { return nil }
        skipSpaces()
        return index == expression.endIndex ? value : nil
    }

    private mutating func parseExpression() -> Double? {
        guard var value = parseTerm() else { return nil }

        while true {
            skipSpaces()
            if consume("+") {
                guard let rhs = parseTerm() else { return nil }
                value += rhs
            } else if consume("-") {
                guard let rhs = parseTerm() else { return nil }
                value -= rhs
            } else {
                return value
            }
        }
    }

    private mutating func parseTerm() -> Double? {
        guard var value = parseFactor() else { return nil }

        while true {
            skipSpaces()
            if consume("*") {
                guard let rhs = parseFactor() else { return nil }
                value *= rhs
            } else if consume("/") {
                guard let rhs = parseFactor(), rhs != 0 else { return nil }
                value /= rhs
            } else {
                return value
            }
        }
    }

    private mutating func parseFactor() -> Double? {
        skipSpaces()

        if consume("-") {
            guard let value = parseFactor() else { return nil }
            return -value
        }

        if consume("(") {
            guard let value = parseExpression(), consume(")") else { return nil }
            return value
        }

        return parseNumber()
    }

    private mutating func parseNumber() -> Double? {
        skipSpaces()
        let start = index

        while index < expression.endIndex {
            let character = expression[index]
            guard character.isNumber || character == "." else { break }
            index = expression.index(after: index)
        }

        guard start != index else { return nil }
        return Double(expression[start..<index])
    }

    private mutating func consume(_ character: Character) -> Bool {
        skipSpaces()
        guard index < expression.endIndex, expression[index] == character else {
            return false
        }
        index = expression.index(after: index)
        return true
    }

    private mutating func skipSpaces() {
        while index < expression.endIndex, expression[index].isWhitespace {
            index = expression.index(after: index)
        }
    }
}
