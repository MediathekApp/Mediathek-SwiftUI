//
//  ProgramUtils.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//


func ProgramFindBestImage(_ program: Program, desiredAspectRatio: Double = 1.0) -> ImageVariant? {
    var bestMatch: ImageVariant? = nil
    var bestMatchAspectRatio = 1000.0
    if let image = program.image {
        for variant in image {
            if let width = variant.width, let height = variant.height {
                let aspectRatio = Double(width) / Double(height)
                if bestMatch == nil || abs(desiredAspectRatio - aspectRatio) < abs(desiredAspectRatio - bestMatchAspectRatio) {
                    bestMatch = variant
                    bestMatchAspectRatio = aspectRatio
                }
            }
        }
    }
    return bestMatch
}
