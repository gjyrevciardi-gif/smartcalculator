//
//  ButtonType.swift
//  Calculator
//
//  Created by Ricardo Montemayor on 18/07/22.
//

import Foundation
import SwiftUI

enum ButtonType: Hashable, CustomStringConvertible {
    case digit(_ digit: Digit)
    case operation(_ operation: ArithmeticOperation)
    case scientific(_ function: ScientificFunction)
    case negative
    case percent
    case decimal
    case equals
    case allClear
    case clear
    case backspace

    var description: String {
        switch self {
        case .digit(let digit):
            return digit.description
        case .operation(let operation):
            return operation.description
        case .scientific(let function):
            return function.description
        case .negative:
            return "+/-"
        case .percent:
            return "%"
        case .decimal:
            return "."
        case .equals:
            return "="
        case .allClear:
            return "AC"
        case .clear:
            return "C"
        case .backspace:
            return "x"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .allClear, .clear, .negative, .percent, .backspace:
            return Color(.lightGray)
        case .operation, .equals:
            return .orange
        case .scientific:
            return Color(.darkGray)
        case .digit, .decimal:
            return .secondary
        }
    }

    var foregroundColor: Color {
        switch self {
        case .allClear, .clear, .negative, .percent, .backspace:
            return .black
        default:
            return .white
        }
    }
}

enum ScientificFunction: Hashable, CustomStringConvertible {
    case sine, cosine, tangent, squareRoot, square, pi

    var description: String {
        switch self {
        case .sine:
            return "sin"
        case .cosine:
            return "cos"
        case .tangent:
            return "tan"
        case .squareRoot:
            return "sqrt"
        case .square:
            return "x^2"
        case .pi:
            return "pi"
        }
    }
}
