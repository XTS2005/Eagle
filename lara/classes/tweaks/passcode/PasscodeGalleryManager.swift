//
//  PasscodeGalleryManager.swift
//  lara
//
//  Created by neonmodder123 on 20/05/2026.
//

import Foundation
import SwiftUI
import Combine

let defaultPasscodeRepoURL = "https://raw.githubusercontent.com/SerStars/Nugget-Wallpapers/main/wallpapers-passthemes.json"
private let passcodeRepoKey = "passcodeThemeRepos"
private let retiredPasscodeRepoURL = "https://raw.githubusercontent.com/neonmodder123/theme-repo/refs/heads/main/passcode-themes.json"

struct PasscodeGalleryTheme: Identifiable, Decodable, Equatable {
    let name: String
    let description: String
    let url: String
    let preview: String
    let authors: String?
    let contact: PasscodeThemeContact?
    let version: String?
    var id: String { url }

    var authorLine: String {
        if let authors, !authors.isEmpty { return authors }
        if let contact { return contact.displayName }
        return LaraL10n.text(en: "Cowabunga community", es: "Comunidad Cowabunga")
    }

    private enum CodingKeys: String, CodingKey {
        case name, description, url, preview, authors, contact, version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        url = try container.decode(String.self, forKey: .url)
        preview = try container.decode(String.self, forKey: .preview)
        authors = try container.decodeIfPresent(String.self, forKey: .authors)
        contact = try container.decodeIfPresent(PasscodeThemeContact.self, forKey: .contact)
        version = try container.decodeIfPresent(String.self, forKey: .version)
    }
}

struct PasscodeThemeContact: Decodable, Equatable {
    private let raw: [String: String]
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = try container.decode([String: String].self)
    }
    var displayName: String {
        raw.map { "\($0.key): \($0.value)" }.first ?? ""
    }
}

struct PasscodeRepoData: Identifiable {
    var id: String { name }
    let name: String
    let author: String?
    let icon: String?
    let themes: [PasscodeGalleryTheme]
    let baseURL: URL
}

struct PasscodeRepoState: Identifiable {
    var id: String { url }
    let url: String
    var isLoading: Bool
    var error: String?
    var data: PasscodeRepoData?
}

@MainActor
final class PasscodeGalleryManager: ObservableObject {
    static let shared = PasscodeGalleryManager()

    @Published var repos: [PasscodeRepoState] = []
    @Published var downloading: Set<String> = []

    private var repoURLs: [String] = loadPasscodeRepoURLs()

    var allThemes: [PasscodeGalleryTheme] { repos.flatMap { $0.data?.themes ?? [] } }
    var themes: [PasscodeGalleryTheme] { allThemes }
    var isLoading: Bool { repos.contains { $0.isLoading } }
    var loadError: String? { repos.first { $0.error != nil }?.error }

    func previewURL(for theme: PasscodeGalleryTheme) -> URL? {
        guard let repoData = repos.first(where: { $0.data?.themes.contains(where: { $0.id == theme.id }) == true })?.data else { return nil }
        if theme.preview.hasPrefix("http") { return URL(string: theme.preview) }
        return repoData.baseURL.appendingPathComponent(theme.preview)
    }

    func downloadURL(for theme: PasscodeGalleryTheme) -> URL? {
        guard let repoData = repos.first(where: { $0.data?.themes.contains(where: { $0.id == theme.id }) == true })?.data else { return nil }
        if theme.url.hasPrefix("http") { return URL(string: theme.url) }
        return repoData.baseURL.appendingPathComponent(theme.url)
    }

    func isDownloading(_ theme: PasscodeGalleryTheme) -> Bool { downloading.contains(theme.id) }

    func loadThemes(forceRefresh: Bool = false) async {
        await refreshRepos(forceRefresh: forceRefresh)
    }

    func refreshRepos(forceRefresh: Bool = false) async {
        repos = repoURLs.map { PasscodeRepoState(url: $0, isLoading: true, error: nil, data: nil) }

        await withTaskGroup(of: (String, Result<PasscodeRepoData, Error>).self) { group in
            for url in repoURLs {
                group.addTask {
                    do {
                        return (url, .success(try await self.fetchRepo(url, forceRefresh: forceRefresh)))
                    } catch {
                        return (url, .failure(error))
                    }
                }
            }
            for await (url, result) in group {
                guard let idx = repos.firstIndex(where: { $0.url == url }) else { continue }
                repos[idx].isLoading = false
                switch result {
                case .success(let data): repos[idx].data = data
                case .failure(let error): repos[idx].error = error.localizedDescription
                }
            }
        }
    }

    func addRepo(_ urlString: String) async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, URL(string: trimmed) != nil, !repoURLs.contains(trimmed) else { return }
        repoURLs.append(trimmed)
        savePasscodeRepoURLs(repoURLs)
        await refreshRepos()
    }

    func removeRepo(_ url: String) {
        guard url != defaultPasscodeRepoURL else { return }
        repoURLs.removeAll { $0 == url }
        savePasscodeRepoURLs(repoURLs)
        Task { await refreshRepos() }
    }

    func downloadAndImport(_ theme: PasscodeGalleryTheme) async throws {
        guard let fileURL = downloadURL(for: theme) else { throw URLError(.badURL) }
        downloading.insert(theme.id)
        defer { downloading.remove(theme.id) }
        let (data, response) = try await URLSession.shared.data(from: fileURL)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard data.count <= 50 * 1024 * 1024 else {
            throw CocoaError(.fileWriteOutOfSpace)
        }
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(theme.name + ".passthm")
        try data.write(to: dest, options: .atomic)
    }

    private func fetchRepo(_ urlString: String, forceRefresh: Bool = false) async throws -> PasscodeRepoData {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        if forceRefresh { req.cachePolicy = .reloadIgnoringLocalCacheData }
        let (data, _) = try await URLSession.shared.data(for: req)
        let baseURL = url.deletingLastPathComponent()

        if let themes = try? JSONDecoder().decode([PasscodeGalleryTheme].self, from: data) {
            let name = urlString == defaultPasscodeRepoURL ? "Nugget Wallpapers" : (url.deletingPathExtension().lastPathComponent)
            return PasscodeRepoData(name: name, author: nil, icon: nil, themes: themes, baseURL: baseURL)
        }

        struct RepoJSON: Decodable {
            let repo_name: String
            let repo_author: String?
            let repo_icon: String?
            let themes: [PasscodeGalleryTheme]
        }
        let parsed = try JSONDecoder().decode(RepoJSON.self, from: data)
        return PasscodeRepoData(name: parsed.repo_name, author: parsed.repo_author, icon: parsed.repo_icon, themes: parsed.themes, baseURL: baseURL)
    }
}

private func loadPasscodeRepoURLs() -> [String] {
    if let data = UserDefaults.standard.data(forKey: passcodeRepoKey),
       let urls = try? JSONDecoder().decode([String].self, from: data), !urls.isEmpty {
        var result = urls.filter { $0 != retiredPasscodeRepoURL }
        if !result.contains(defaultPasscodeRepoURL) { result.insert(defaultPasscodeRepoURL, at: 0) }
        return result
    }
    return [defaultPasscodeRepoURL]
}

private func savePasscodeRepoURLs(_ urls: [String]) {
    if let encoded = try? JSONEncoder().encode(urls) {
        UserDefaults.standard.set(encoded, forKey: passcodeRepoKey)
    }
}
