# Qualtrics Survey & Response Migration Utility

Local Python CLI for migrating **one Qualtrics survey** (QSF definition) and its **historical response data** from a source account/brand to a destination account/brand.

## Windows sharing

The project is intended to be shared as a Windows release ZIP containing `qualtrics-migrator.exe` and the launcher. Recipients need **Windows 10/11**, internet access to their Qualtrics datacenters, and their own source/destination API tokens; they do not need to install Python.

To create the release executable, build it on Windows with Python 3.10+ using `build-windows.ps1`; this project build prerequisite is for the maintainer only. Share the resulting `dist\windows-release` folder as a ZIP. Do not send `.env`, `.venv`, `state/`, `staged/`, `input/`, `output/`, or generated reports. Those can contain API credentials or survey response data. The release ZIP should contain the executable, launcher, `.env.example`, and README only.

Recipient setup:

1. Extract the Windows release ZIP to a location they can write to.
2. Open PowerShell in that folder and run:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\run-windows.ps1
   ```

3. The first launch creates `.env`. Edit it with the recipient's own Qualtrics base URLs and tokens, then run the launcher again.

PowerShell's process-scoped execution policy change applies only to that PowerShell window. The launcher does not start a migration by itself; the menu's live migration path still requires its confirmation prompt. Use a dedicated non-production brand for initial validation.

## Requirements

- Python 3.10+
- Source and destination Qualtrics API tokens with survey read/write and response export/import permissions
- Non-production test accounts recommended for first runs

## Setup

```powershell
cd "CLI Survey Migration Utility"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
copy .env.example .env
```

Edit `.env` with your datacenter base URLs and API tokens. Never commit `.env`.

## Run

```powershell
python main.py
```

After installation, the `qualtrics-migrator` command is also available inside the activated environment. `python main.py` remains supported for source checkouts.

Interactive menu:

1. Configure Source Account  
2. Configure Destination Account  
3. List Source Surveys  
4. Migrate Selected Survey(s)  
5. Check Migration Status  
6. Exit  

Dry-run defaults to `true` (`DRY_RUN_DEFAULT`). During migrate you will be asked to confirm live (mutating) operations.

During option 4, enter one or more comma-separated values. Each value can be a survey number from the displayed table, an exact survey ID, or an exact survey name. For example:

```text
1, SV_abc123, Product Feedback Survey
```

Duplicate selections are ignored. Survey names must match exactly (case-insensitive) and duplicate names must be selected by survey ID or number. Selected surveys currently run sequentially so each migration has isolated memory, API polling, staged files, and SQLite state. If option 4 finds an incomplete run for a selected survey, it asks whether to resume that run instead of creating a duplicate run.

## Workflow

1. Validate source/destination credentials (`whoami`)
2. List and select one source survey
3. Preflight checks
4. Export survey definition (QSF)
5. Export responses (CSV, often inside a ZIP)
6. Import QSF into destination; persist new survey ID
7. Validate CSV headers / field mapping
8. Import responses; poll until terminal status
9. Write sanitized JSON and text reports under `reports/`

State is stored in SQLite (`MIGRATION_STATE_DB`) so polling can resume after interruption. Ambiguous import POST outcomes are marked `PENDING_RECONCILIATION` and are **not** auto-retried (avoids duplicate responses).

If the process stops while a run is in a persisted pending state, choose option 4 again, select the same survey ID/name/number, and answer `yes` when asked to resume the existing run. Option 5 with the run ID remains available for manual status/resume. A saved response-import progress ID is polled instead of submitting another response import. Recoverable export checkpoints are resumed automatically. If a failure occurred after a survey or response submission but before a progress identifier was saved, the run is marked `PENDING_RECONCILIATION`; check the destination account before retrying so the utility cannot create duplicates.

## Tests

```powershell
pytest -q
```

## Non-production test procedure

1. Use a dedicated test brand and a small synthetic survey with a few responses.
2. Run with dry-run first, then a live migrate.
3. Confirm destination survey ID, response counts, and field values in the Qualtrics UI.
4. Only then consider large datasets (API size limits apply; this tool does not split CSVs).

## Security

- Tokens are never logged or written to reports.
- Exported data under `staged/`, `input/`, `output/`, and reports may contain PII — protect and retain appropriately.
- TLS certificate verification is always enabled.
