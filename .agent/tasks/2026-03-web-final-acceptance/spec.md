# Task Spec

## ID
2026-03-web-final-acceptance

## Role pass
qa-verifier

## Goal
Determine whether the repository meets the requested stop condition: a genuinely usable local web app with truthful proof artifacts, while keeping iOS validation green and limitations explicit.

## Acceptance target
- Working web app under `web/`
- Web `typecheck`, `test`, and `build` pass locally
- Relevant Swift/iOS validation passes locally on this machine
- Proof-loop artifacts updated truthfully, including confidence categories
- README and web docs match the actual final supported scope

## Required truth categories
- logic confidence
- runtime confidence
- UI confidence
- real-device confidence

## Stop conditions
- `accepted` only if web and local Swift/iOS validation are green and the app is meaningfully usable
- `accepted_with_conditions` only if remaining gaps are explicitly documented and are not silent trust failures
- `rejected` if core trust or validation requirements remain broken
