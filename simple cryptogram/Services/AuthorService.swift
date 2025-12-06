import Foundation

@MainActor
@Observable
class AuthorService {
    private(set) var currentAuthor: Author?
    private(set) var isLoading: Bool = false
    
    private let databaseService: DatabaseService
    private var lastAuthorName: String?
    
    init(databaseService: DatabaseService = DatabaseService.shared) {
        self.databaseService = databaseService
    }
    
    func loadAuthorIfNeeded(name: String) {
        guard name != lastAuthorName else { return }
        lastAuthorName = name
        isLoading = true
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let author = try await self.databaseService.fetchAuthor(byName: name)
                await MainActor.run {
                    self.currentAuthor = author
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.currentAuthor = nil
                    self.isLoading = false
                }
            }
        }
    }
    
    func clearAuthor() {
        currentAuthor = nil
        lastAuthorName = nil
        isLoading = false
    }
}