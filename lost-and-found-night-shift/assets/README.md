# External collectible upload payloads

`oxford_shoe_meshonly.glb.gz.b64` is a deterministic transport payload for the user-selected Sketchfab Oxford shoe. The Roblox upload workflow decodes base64, gunzips it, verifies the exact GLB byte count and SHA256, uploads it through the existing Assets-capable Open Cloud key, grants LOST & FOUND Universe use permission, and records the returned Asset ID.

This payload is not loaded directly by Roblox runtime code.
