# DBA — index

- [DISCOVERED] drift 2.35.3 with sqlite3 3.8.0, pinned. Schema version 1: tables alarms, sounds, weights, ring_sessions and ring_events. On the web the data is in IndexedDB, through `web/drift_worker.js` and `web/sqlite3.wasm`. Any table change needs schema version 2 and a migration (docs/DECISIONS.md 2.1).
- 2026-11-03 · task 2.5a: schema version 2 adds `ring_plans` (primary key alarm and moment of the ring, a foreign key to the alarm). `onUpgrade` only creates the table, so rows of version 1 stay. `test/data/migration_test.dart` holds the SQL of version 1 as it was, with rows in every table: it must never change, and each later version adds its step there.
