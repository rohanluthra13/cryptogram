import SwiftUI

struct AuthorInfoView: View {
    let author: Author
    var excludedPlaces: [String] = [] // Example usage for filtering out certain places
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(author.fullName ?? author.name)
                .font(.headline)
            if let birth = author.birthDate, !birth.isEmpty {
                Text("Born: \(birth)")
                    .font(.subheadline)
            }
            if let pob = author.placeOfBirth, !pob.isEmpty, !excludedPlaces.contains(where: { pob.localizedCaseInsensitiveContains($0) }) {
                Text("Place of Birth: \(pob)")
                    .font(.subheadline)
            }
            if let death = author.deathDate, !death.isEmpty {
                Text("Died: \(death)")
                    .font(.subheadline)
            }
            if let pod = author.placeOfDeath, !pod.isEmpty, !excludedPlaces.contains(where: { pod.localizedCaseInsensitiveContains($0) }) {
                Text("Place of Death: \(pod)")
                    .font(.subheadline)
            }
            if let summary = author.summary, !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
        .shadow(radius: 2)
    }
}

#if DEBUG
struct AuthorInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorInfoView(author: Author(id: 1, name: "Jane Doe", fullName: "Jane A. Doe", birthDate: "1900-01-01", deathDate: "1980-12-31", placeOfBirth: "London", placeOfDeath: "Paris", summary: "A famous author."))
            .previewLayout(.sizeThatFits)
    }
}
#endif
