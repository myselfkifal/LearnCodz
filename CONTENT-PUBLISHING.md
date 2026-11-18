# Publishing lesson content

The current app reads bundled courses. A future content feed should carry stable lesson and question IDs, language, chapter position, publication status, lesson sections and example code. Each lesson or question can have an optional HTTPS image URL and an accessible image description. An unavailable picture must not block learning.

For each choice question, store its options and the correct option ID, plus feedback. Convert that ID to the internal answer index when loading the question. The quiz supports different choice counts; use only meaningful distractors. The app balances displayed answer positions independently of stored content. Code-order questions retain their authored line identifiers and correct sequence.

Keep draft content private, fetch only published revisions, and cache validated content on the device. For offline pictures, download image files separately from lesson data. Keep bundled lessons as the fallback. This is a design note; a hosted content feed is not connected yet.
