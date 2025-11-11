//
//  AppState.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import Foundation

@Observable
final class AppState {
    var isSignedIn: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
}

