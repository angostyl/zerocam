import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum FilmRecipe: String, CaseIterable, Identifiable {
    case processZero = "Process Zero"
    case portra400 = "Portra 400"
    case classicChrome = "Classic Chrome"
    case triX400 = "Tri-X 400"

    var id: String { rawValue }

    var badgeText: String {
        switch self {
        case .processZero: return "ZERO"
        case .portra400: return "PORTRA"
        case .classicChrome: return "CHROME"
        case .triX400: return "TRI-X"
        }
    }

    var description: String {
        switch self {
        case .processZero: return "Ótica pura sem tone-mapping ou sharpening artificial."
        case .portra400: return "Cores quentes, tons de pele dourados e sombras suaves."
        case .classicChrome: return "Saturação contida, sombras profundas e contraste cinematográfico."
        case .triX400: return "Preto e branco clássico de alto contraste com grão orgânico."
        }
    }
}

final class FilmFilterEngine {
    static let shared = FilmFilterEngine()
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func applyRecipe(_ recipe: FilmRecipe, to inputImage: UIImage) -> UIImage {
        guard recipe != .processZero else { return inputImage }
        guard let ciInput = CIImage(image: inputImage) else { return inputImage }

        var output = ciInput

        switch recipe {
        case .processZero:
            return inputImage

        case .portra400:
            // 1. Temperatura quente e suave elevação de sombras
            let tempFilter = CIFilter.temperatureAndTint()
            tempFilter.inputImage = output
            tempFilter.neutral = CIVector(x: 6500, y: 0)
            tempFilter.targetNeutral = CIVector(x: 5900, y: 15) // Leve aquecimento Portra
            if let result = tempFilter.outputImage { output = result }

            // 2. Curva tonal suave e saturação moderada nos tons de pele
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = output
            colorFilter.saturation = 1.08
            colorFilter.contrast = 1.05
            colorFilter.brightness = 0.02
            if let result = colorFilter.outputImage { output = result }

        case .classicChrome:
            // Saturação contida (-22%) e aumento de contraste de sombras
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = output
            colorFilter.saturation = 0.78
            colorFilter.contrast = 1.18
            colorFilter.brightness = -0.02
            if let result = colorFilter.outputImage { output = result }

            let tempFilter = CIFilter.temperatureAndTint()
            tempFilter.inputImage = output
            tempFilter.neutral = CIVector(x: 6500, y: 0)
            tempFilter.targetNeutral = CIVector(x: 6700, y: -8) // Leve tom frio / ciano
            if let result = tempFilter.outputImage { output = result }

        case .triX400:
            // P&B com curva sigmoide acentuada (Tri-X 400)
            let monoFilter = CIFilter.photoEffectMono()
            monoFilter.inputImage = output
            if let result = monoFilter.outputImage { output = result }

            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = output
            colorFilter.contrast = 1.35
            colorFilter.brightness = -0.03
            if let result = colorFilter.outputImage { output = result }
        }

        guard let cgImg = context.createCGImage(output, from: output.extent) else {
            return inputImage
        }
        return UIImage(cgImage: cgImg, scale: inputImage.scale, orientation: inputImage.imageOrientation)
    }
}
