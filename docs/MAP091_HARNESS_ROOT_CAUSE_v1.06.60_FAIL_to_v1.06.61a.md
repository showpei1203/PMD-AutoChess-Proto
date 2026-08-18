# Map091 v1.06.60 FAIL Root Cause

Windows evidence:
- Source events/pages/graphics/triggers/lists: healthy.
- Parser: 12/12 PASS.
- Content matrix: 126/126 PASS.
- Runtime materialization: 9 events / 9 plan events.
- Game_Map Marshal roundtrip: PASS.
- Hunt session Marshal roundtrip: PASS.

The failure was TEST-only:
1. Legacy v1.06.49 audit calls `vxrd_template_entries_v10649(map,1,nil,nil)`. After v1.06.52, Encounter/Rare/Elite/Info are Hunt-filtered; code=nil excludes them, producing the expected historical missing-role set.
2. v1.06.60 clone test required `Marshal.dump(Marshal.load(blob)) == blob`. Re-dump byte identity is not the contract used by Runtime. Runtime contract is a deep independent object graph carrying equivalent event semantics.

v1.06.61a replaces the clone test with canonical semantic-state equality plus independent Event/Pages/Page/List object identities. Offline verification on Formal Map091.rvdata = 49/49 PASS.
