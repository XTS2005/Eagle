//
//  LinkCreditCell.swift
//  PartyUI
//
//  Created by lunginspector on 3/3/26.
//

import SwiftUI

public struct LinkCreditCell<Icon: View>: View {
    var image: Icon
    var name: String
    var description: String
    var url: String
    @Environment(\.openURL) var openURL
    
    public init(name: String, description: String, url: String = "", @ViewBuilder image: () -> Icon) {
        self.image = image()
        self.name = name
        self.description = description
        self.url = url
    }
    
    public var body: some View {
        Button(action: {
            if !url.isEmpty { openURL(URL(string: url)!) }
        }) {
            HStack(spacing: spacing.creditCell) {
                image
                VStack(alignment: .leading) {
                    Text(name)
                        .fontWeight(.semibold)
                    Text(description)
                        .multilineTextAlignment(.leading)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !url.isEmpty {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .imageScale(.small)
                }
            }
        }
        .foregroundStyle(Color(.label))
    }
}

// icon for credits cell
public struct LinkCreditIcon: View {
    var url: String
    
    init(url: String) {
        self.url = url
    }
    
    public var body: some View {
        if #available(iOS 19.0, *) {
            AsyncImage(url: URL(string: url)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                    .glassEffect(.regular, in: Circle())
            } placeholder: {
                ProgressView()
                    .frame(width: 40, height: 40)
            }
        } else {
            AsyncImage(url: URL(string: url)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    }
            } placeholder: {
                ProgressView()
                    .frame(width: 40, height: 40)
            }
        }
    }
}
