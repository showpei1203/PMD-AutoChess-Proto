# Source downloads without manual AYN THOR transfer

User action only after syncing the new GitHub branch to Surface:

1. Run `RUN_FETCH_3_WINDOWS.bat` from the Godot project folder. Python 3 is necessary (Python downloads page: https://www.python.org/downloads/windows/).
2. When output shows `#025`, `#094`, `#143` as OK with nonzero PNG counts, verify `data/raw/pmdcollab/0025`, `0094`, `0143`. They contain `AnimData.xml`, `*-Anim.png`, `*-Offsets.png`, `*-Shadow.png`, `credits_upstream.txt` when the credits source responds, and `provenance.json`.
3. Run `RUN_FETCH_151_WINDOWS.bat` to download all 151. Existing verified entries are cached. Check `reports/pmdcollab_download_report.json` for failed IDs and unresolved credit statuses.

This is a genuine downloader that contacts the public website, not a request for local files. It is intentionally separate from the old `pmd_asset_audit.py` for Gen1recomp legacy MOD layout, because the two asset formats differ. Before Godot animation import, use the original PMD `AnimData.xml` dimensions, actions, hit frames and original PNG offsets. Do not assume all 151 creatures have every motion.

Run offline tests: `RUN_TESTS_WINDOWS.bat` or `py -3 -m unittest discover -s tests -v`.

Status: GitHub API indexes for three species confirmed, local offline tests PASS, real runtime downloading to Surface PENDING. Do not mistake planned 151 URLs or unit tests for actual downloaded image files.