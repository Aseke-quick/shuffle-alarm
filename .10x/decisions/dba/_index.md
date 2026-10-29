# DBA — index

- [DISCOVERED] drift 2.35.3 with sqlite3 3.8.0, pinned. Schema version 1: tables alarms, sounds, weights, ring_sessions and ring_events. On the web the data is in IndexedDB, through `web/drift_worker.js` and `web/sqlite3.wasm`. Any table change needs schema version 2 and a migration (docs/DECISIONS.md 2.1).
