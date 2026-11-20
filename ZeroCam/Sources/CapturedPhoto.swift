import UIKit
import Photos

struct CapturedPhoto: Identifiable, Equatable {
    let id: UUID
    let image: UIImage
    let date: Date
    let recipe: FilmRecipe
    let lens: String
    let iso: Int
    let shutterSpeed: String
    let ev: Float
    let isRaw: Bool
    var assetLocalIdentifier: String?

    static func == (lhs: CapturedPhoto, rhs: CapturedPhoto) -> Bool {
        lhs.id == rhs.id
    }
}
