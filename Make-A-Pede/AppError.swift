//
//  AppError.swift
//  Make-A-Pede
//
//  Copyright © 2018 Automata Development. GPL v3 License.
//

public enum AppError : Error {
	case dataCharactertisticNotFound
	case enabledCharactertisticNotFound
	case updateCharactertisticNotFound
	case serviceNotFound
	case invalidState
	case resetting
	case poweredOff
	case unknown
	case unlikely
}
