# Evidence Report

## Task
- ID: TASK_ID
- Title: Task title

## What was implemented
Кратко по сути:
- ...
- ...
- ...

## Files changed
- ...
- ...
- ...
- ...

## Commands executed
List only commands actually executed:
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`
- `make ci`
- `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- `bash ./scripts/run_xcode_coverage.sh`
- `bash ./scripts/check_coverage_policy.sh`
- Focused host/UI test(s):
  - `...`
  - `...`

## Results
Summarize actual results:
- passed / failed
- what exactly was confirmed
- what remained outside scope

## Runtime / host UI evidence
- Which host/UI tests ran
- Which user-facing flows were actually exercised
- Which screens/actions were confirmed working
- Any runtime bug found and fixed during the pass

## Rules / logic evidence
- Which rules/golden/scenario tests were updated or executed
- Which calculations or invariants were actually confirmed
- Whether explainability/breakdown behavior was validated

## Data safety evidence
- Detached-copy behavior confirmed? yes/no
- Replace-all confirmation confirmed? yes/no
- Existing saved entities preserved? yes/no
- Persistence backend observability unchanged? yes/no
- Notes:
  - ...
  - ...

## UI / visual evidence
- Screenshot pass executed? yes/no
- Manual screenshot review executed? yes/no
- Real device visual pass executed? yes/no
- Known UI issues observed:
  - ...
  - ...

## Coverage / CI evidence
- `make ci` passed? yes/no
- truthful coverage gate passed? yes/no
- package surface coverage:
  - ...
- Rules/Application/etc if relevant:
  - ...
- Notes:
  - ...

## Real-device evidence
- Real iPhone pass executed? yes/no
- Real iPad pass executed? yes/no
- Files picker verified on device? yes/no
- Share destinations verified on device? yes/no
- Hard-kill relaunch verified on device? yes/no

## Unverified risks
List only real gaps in evidence:
- ...
- ...
- ...

## Residual issues
List remaining non-blocking issues or caveats:
- ...
- ...
- ...

## Recommended verdict
- accepted
- accepted_with_conditions
- rejected

## Recommended next step
- ...
- ...
- ...
