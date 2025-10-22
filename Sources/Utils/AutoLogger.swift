//
//  AutoLogger.swift
//  Flipper
//
//  Created by Sushant Verma on 19/10/2025.
//


@_exported import os.log
import Foundation

class AutoLogger {

    static func unifiedLogger(category: String = #function) -> os.Logger {
        os.Logger(subsystem: Bundle.main.bundleIdentifier!,
                  category: category)
    }
}
