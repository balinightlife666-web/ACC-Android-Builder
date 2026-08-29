-- LOST & FOUND: NIGHT SHIFT — external collectible asset registry
-- Asset IDs are written only by the verified Roblox Open Cloud upload workflow.
-- A zero ID means: use the existing procedural collectible fallback.

return {
    version = "M5C3_EXTERNAL_ASSETS_V1",
    Models = {
        daniel_formal_shoe = {
            assetId = 0, -- ROBLOX_ASSET_ID
            sourceTitle = "Oxford style leather shoe for men",
            sourceCreator = "assetfactory",
            sourcePlatform = "Sketchfab",
            sourceLicense = "Free Standard",
            sourceUrl = "https://sketchfab.com/3d-models/oxford-style-leather-shoe-for-men-632ce6f25dec417e81b6998bae1ea3e1",
            sourceTriangles = 13568,
            sourceVerticesApprox = 6900,
            optimizedSha256 = "82ed5b004820e77f95599e7da1254f322b0ebe446eeafab2083cc519dcbd83ef",
            optimizedBytes = 449448,
            note = "Mesh-only Roblox upload derivative; silhouette retained, embedded high-resolution PBR textures removed for runtime weight. Procedural fallback remains authoritative if loading fails.",
        },
    },
}
