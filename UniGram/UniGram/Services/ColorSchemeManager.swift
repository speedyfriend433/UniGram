//
//  ColorSchemeManager.swift
//  UniGram
//
//  Created by 이지안 on 2/11/25.
//

import SwiftUI

class ColorSchemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    func toggleColorScheme() {
        isDarkMode.toggle()
    }
}
