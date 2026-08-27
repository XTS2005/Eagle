//
//  SectionPlatter.swift
//  PartyUI
//
//  Created by lunginspector on 3/3/26.
//

import SwiftUI

// MARK: SectionPlatter
public struct SectionPlatter: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: cornerRad.platter, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRad.platter, style: .continuous)
                    .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

