//
//  Calculator.swift
//  Calculator
//
//  Created by Ricardo Montemayor on 20/07/22.
//

import Foundation

struct Calculator {
    struct HistoryEntry: Identifiable, Equatable, Codable {
        let id = UUID()
        let expression: String
        let result: String
    }

    // MARK: - PROPERTIES

    private var newNumber: Decimal? {
        didSet {
            guard newNumber != nil else { return }
            carryingNegative = false
            carryingDecimal = false
            carryingZeroCount = 0
            pressedClear = false
        }
    }
    private var queuedNumbers: [Decimal] = []
    private var queuedOperations: [ArithmeticOperation] = []
    private var result: Decimal?
    private(set) var history: [HistoryEntry] = Self.loadHistory()

    private var carryingNegative: Bool = false
    private var carryingDecimal: Bool = false
    private var carryingZeroCount: Int = 0

    private var pressedClear: Bool = false

    // MARK: - COMPUTED PROPERTIES

    var displayText: String {
        return getNumberString(forNumber: number, withCommas: true)
    }

    var expressionText: String {
        var parts: [String] = []

        for index in queuedNumbers.indices {
            parts.append(getNumberString(forNumber: queuedNumbers[index], withCommas: true))

            if queuedOperations.indices.contains(index) {
                parts.append(queuedOperations[index].description)
            }
        }

        if let newNumber, !queuedOperations.isEmpty {
            parts.append(getNumberString(forNumber: newNumber, withCommas: true))
        }

        return parts.joined(separator: " ")
    }

    var showAllClear: Bool {
        newNumber == nil && queuedNumbers.isEmpty && queuedOperations.isEmpty && result == nil || pressedClear
    }

    var number: Decimal? {
        if pressedClear || carryingDecimal {
            return newNumber
        }
        return newNumber ?? result ?? queuedNumbers.last
    }

    private var containsDecimal: Bool {
        return getNumberString(forNumber: number).contains(".")
    }

    // MARK: - OPERATIONS

    mutating func setDigit(_ digit: Digit) {
        if containsDecimal && digit == .zero {
            carryingZeroCount += 1
        } else if canAddDigit(digit) {
            let numberString = getNumberString(forNumber: newNumber)
            newNumber = Decimal(string: numberString.appending("\(digit.rawValue)"))
        }
    }

    mutating func backspace() {
        if newNumber == nil, !queuedOperations.isEmpty {
            queuedOperations.removeLast()
            newNumber = queuedNumbers.popLast()
            result = nil
            return
        }

        if carryingDecimal {
            carryingDecimal = false
            return
        }

        if carryingZeroCount > 0 {
            carryingZeroCount -= 1
            return
        }

        guard var numberString = newNumber.map(String.init), !numberString.isEmpty else { return }

        if numberString.count == 1 || (numberString.count == 2 && numberString.hasPrefix("-")) {
            if !queuedOperations.isEmpty {
                queuedOperations.removeLast()
                newNumber = queuedNumbers.popLast()
                result = nil
                return
            }
        }

        numberString.removeLast()

        if numberString.isEmpty || numberString == "-" {
            newNumber = nil
        } else {
            newNumber = Decimal(string: numberString)
        }
    }

    mutating func setOperation(_ operation: ArithmeticOperation) {
        if newNumber == nil, !queuedOperations.isEmpty {
            queuedOperations[queuedOperations.count - 1] = operation
            return
        }

        guard let number = newNumber ?? result else { return }
        queuedNumbers.append(number)
        queuedOperations.append(operation)
        newNumber = nil
        result = nil
    }

    mutating func setScientificFunction(_ function: ScientificFunction) {
        switch function {
        case .pi:
            newNumber = Decimal(Double.pi)
        case .sine:
            applyDoubleFunction { sin($0 * Double.pi / 180) }
        case .cosine:
            applyDoubleFunction { cos($0 * Double.pi / 180) }
        case .tangent:
            applyDoubleFunction { tan($0 * Double.pi / 180) }
        case .squareRoot:
            applyDoubleFunction { sqrt($0) }
        case .square:
            guard let current = number else { return }
            result = current * current
            newNumber = nil
            queuedNumbers.removeAll()
            queuedOperations.removeAll()
        }
    }

    mutating func toggleSign() {
        if let number = newNumber {
            newNumber = -number
            return
        }
        if let number = result {
            result = -number
            return
        }

        carryingNegative.toggle()
    }

    mutating func setPercent() {
        if let number = newNumber {
            newNumber = number / 100
            return
        }
        if let number = result {
            result = number / 100
            return
        }
    }

    mutating func setDecimal() {
        if containsDecimal { return }
        carryingDecimal = true
    }

    mutating func evaluate(markupPercent: Decimal) {
        guard let finalNumber = newNumber, !queuedOperations.isEmpty else { return }

        let numbers = queuedNumbers + [finalNumber]
        guard var subtotal = numbers.first else { return }

        for operationIndex in queuedOperations.indices {
            let nextNumber = numbers[operationIndex + 1]

            switch queuedOperations[operationIndex] {
            case .addition:
                subtotal += nextNumber
            case .subtraction:
                subtotal -= nextNumber
            case .multiplication:
                subtotal *= nextNumber
            case .division:
                subtotal /= nextNumber
            }
        }

        let totalWithMarkup = subtotal + (subtotal * markupPercent / 100)
        result = rounded(totalWithMarkup)
        history.insert(HistoryEntry(
            expression: "\(expressionText) + \(getNumberString(forNumber: markupPercent, withCommas: true))%",
            result: getNumberString(forNumber: result, withCommas: true)
        ), at: 0)
        saveHistory()
        newNumber = nil
        queuedNumbers.removeAll()
        queuedOperations.removeAll()
    }

    mutating func allClear() {
        newNumber = nil
        queuedNumbers.removeAll()
        queuedOperations.removeAll()
        result = nil
        carryingNegative = false
        carryingDecimal = false
        carryingZeroCount = 0
    }

    mutating func clear() {
        newNumber = nil
        carryingNegative = false
        carryingDecimal = false
        carryingZeroCount = 0

        pressedClear = true
    }

    mutating func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    // MARK: - HELPERS

    func operationIsHighlighted(_ operation: ArithmeticOperation) -> Bool {
        return queuedOperations.last == operation && newNumber == nil
    }

    private func getNumberString(forNumber number: Decimal?, withCommas: Bool = false) -> String {
        var numberString = (withCommas ? number?.formatted(.number) : number.map(String.init)) ?? "0"

        if carryingNegative {
            numberString.insert("-", at: numberString.startIndex)
        }

        if carryingDecimal {
            numberString.insert(".", at: numberString.endIndex)
        }

        if carryingZeroCount > 0 {
            numberString.append(String(repeating: "0", count: carryingZeroCount))
        }

        return numberString
    }

    private func canAddDigit(_ digit: Digit) -> Bool {
        return number != nil || digit != .zero
    }

    private func rounded(_ value: Decimal) -> Decimal {
        var valueToRound = value
        var roundedValue = Decimal()
        NSDecimalRound(&roundedValue, &valueToRound, 0, .plain)
        return roundedValue
    }

    private mutating func applyDoubleFunction(_ transform: (Double) -> Double) {
        guard let current = number else { return }
        let doubleValue = NSDecimalNumber(decimal: current).doubleValue
        let transformed = transform(doubleValue)
        guard transformed.isFinite else { return }
        result = Decimal(transformed)
        newNumber = nil
        queuedNumbers.removeAll()
        queuedOperations.removeAll()
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: "calculatorHistory")
    }

    private static func loadHistory() -> [HistoryEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: "calculatorHistory"),
            let history = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else {
            return []
        }

        return history
    }
}
