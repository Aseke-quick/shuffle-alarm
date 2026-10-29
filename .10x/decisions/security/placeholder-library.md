# Security: placeholder-library (task 2.3)

- **Review:** `reviews/2026-10-30-2.2a-2.3-security.md`. Pass.
- **Decisions:**
  - `tool/generate_placeholder_library.dart` synthesizes the clips. It imports only `dart:` libraries and downloads nothing. License `original`.
  - The sync never saves over or deletes a user's song or voice message. A manifest id that one of them has is skipped as a clash (three tests).
  - The sync's log lines hold clip ids only.
- **Open:** nothing.
