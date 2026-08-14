//
//  PasscodeRepoView.swift
//  lara
//
//  Created by neonmodder123 on 20/05/2026.
//

import SwiftUI
import Combine

struct PasscodeRepoView: View {
    @ObservedObject private var gallery = PasscodeGalleryManager.shared
    @State private var showAddRepo = false
    @State private var newRepoURL = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(gallery.repos) { repo in
                        HStack(spacing: 12) {
                            if let icon = repo.data?.icon,
                               let iconURL = URL(string: icon) {
                                AsyncImage(url: iconURL) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img
                                            .resizable()
                                            .interpolation(.low)
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 220)
                                    default:
                                        Image(systemName: "shippingbox")
                                            .resizable()
                                            .scaledToFit()
                                            .padding(6)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 42, height: 42)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(repo.data?.name ?? repo.url)
                                    .font(.headline)

                                if let author = repo.data?.author,
                                   !author.isEmpty {
                                    Text(author)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if repo.isLoading {
                                ProgressView()
                            } else if let error = repo.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .lineLimit(1)
                            } else if repo.url != defaultPasscodeRepoURL {
                                Button(role: .destructive) {
                                    gallery.removeRepo(repo.url)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                        .swipeActions {
                            if repo.url != defaultPasscodeRepoURL {
                                Button(role: .destructive) {
                                    gallery.removeRepo(repo.url)
                                } label: {
                                    Text("Remove")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Repos")
                }
            }
            .navigationTitle("Passcode Repos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newRepoURL = ""
                        showAddRepo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { await gallery.refreshRepos(forceRefresh: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Add Passcode Repo", isPresented: $showAddRepo) {
                TextField("URL", text: $newRepoURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                Button("Add") {
                    Task { await gallery.addRepo(newRepoURL) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter the URL to a passcode theme repo JSON.")
            }
        }
    }
}
