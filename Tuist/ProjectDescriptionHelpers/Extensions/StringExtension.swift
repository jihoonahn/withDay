import Foundation

extension String {
    /// `Project<HomeFeature>` → `HomeFeature`
    var extractedGenericTypeName: String {
        guard let start = self.firstIndex(of: "<"),
              let end = self.lastIndex(of: ">"),
              start < end else { return self }

        let inner = self[self.index(after: start)..<end]
        return String(inner)
    }
}
