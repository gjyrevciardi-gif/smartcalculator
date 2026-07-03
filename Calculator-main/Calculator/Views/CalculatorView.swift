//
//  CalculatorView.swift
//  Calculator
//
//  Created by Ricardo Montemayor on 18/07/22.
//

import SwiftUI

// MARK: - BODY

struct CalculatorView: View {

    @EnvironmentObject private var viewModel: ViewModel

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 16) {
                topBar

                if viewModel.showMarkupSettings {
                    markupSettings
                }

                switch viewModel.mode {
                case .basic, .scientific:
                    calculatorSurface
                case .convert:
                    conversionSurface
                case .mathNotes:
                    mathNotesSurface
                }
            }
            .padding(Constants.padding)
            .background(Color.black)

            if viewModel.showHistory {
                historyPanel
            }
        }
    }
}

// MARK: - PREVIEWS

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorView()
            .environmentObject(CalculatorView.ViewModel())
    }
}

// MARK: - COMPONENTS

extension CalculatorView {
    private var topBar: some View {
        HStack {
            Button {
                viewModel.showHistory.toggle()
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 34)
                    .background(Color(.darkGray))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()

            Button {
                viewModel.showMarkupSettings.toggle()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 34)
                    .background(Color(.darkGray))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.top, 8)
    }

    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("History")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    viewModel.showHistory = false
                } label: {
                    Text("x")
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color(.darkGray))
                        .clipShape(Circle())
                }
            }

            if viewModel.history.isEmpty {
                Text("No calculations yet")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(viewModel.history) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.expression)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                Text(entry.result)
                                    .foregroundColor(.white)
                                    .font(.title3.weight(.bold))
                            }
                            Divider()
                                .background(Color.gray)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.07, blue: 0.07))
    }

    private var markupSettings: some View {
        HStack {
            Text("Markup")
                .foregroundColor(.white)
                .font(.headline)

            Spacer()

            TextField("20", text: $viewModel.markupPercent)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
                .frame(width: 72)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("%")
                .foregroundColor(.orange)
                .font(.headline)
        }
        .padding()
        .background(Color(.darkGray))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var calculatorSurface: some View {
        VStack(spacing: Constants.padding) {
            Spacer()
            expressionText
            displayText
            buttonPad
        }
    }

    private var expressionText: some View {
        Text(viewModel.expressionText)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .bottomLeading)
            .font(.system(size: 22, weight: .regular))
            .lineLimit(1)
    }

    private var displayText: some View {
        Text(viewModel.displayText)
            .padding()
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .font(.system(size: 88, weight: .light))
            .lineLimit(1)
            .minimumScaleFactor(0.2)
    }

    private var buttonPad: some View {
        VStack(spacing: Constants.padding) {
            ForEach(viewModel.buttonTypes, id: \.self) { row in
                HStack(spacing: Constants.padding) {
                    ForEach(row, id: \.self) { buttonType in
                        CalculatorButton(buttonType: buttonType)
                    }
                }
            }
        }
    }

    private var conversionSurface: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Category", selection: $viewModel.conversionCategory) {
                ForEach(CalculatorView.ViewModel.ConversionCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                TextField("0", text: $viewModel.conversionInput)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                Text(viewModel.conversionSourceUnit)
                    .foregroundColor(.gray)
                    .font(.title2)
            }

            HStack {
                Spacer()
                Text(viewModel.conversionResult)
                    .foregroundColor(.orange)
                    .font(.system(size: 52, weight: .light))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.top, 24)
    }

    private var mathNotesSurface: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextEditor(text: $viewModel.mathNoteText)
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color(.darkGray))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 220)

            HStack {
                Spacer()
                Text(viewModel.mathNoteResult)
                    .foregroundColor(.orange)
                    .font(.system(size: 56, weight: .light))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}
