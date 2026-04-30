# OPERATIONS.md

> Last updated: 2026-04-30
> Supersedes: scattered notes in CLAUDE.md §4, RESET_PLAN_2026-04-27.md §7–8

---

## 1. Branching & Commits

**Model:** trunk-based — `main` is always deployable.

| Branch prefix             | When to use                  |
| ------------------------- | ---------------------------- |
| `feat/RS-XXX-description` | New feature tied to a ticket |
| `fix/RS-XXX-description`  | Bug fix tied to a ticket     |
| `chore/description`       | Tooling, CI, deps, reorg     |
| `docs/description`        | Documentation only           |

**Rules:**

- `main` is protected. No direct pushes. All changes via PR.
- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`.
- Branches are deleted after merge.

---

## 2. Pull Request Process

1. Open PR against `main`.
2. Fill out the PR template (goal, checklist).
3. Run `/review` via gstack before requesting review.
4. Run `/cso` if the PR touches auth, payments, RLS, or secrets.
5. All CI checks must be green before merge.
6. Squash-merge preferred for feature branches; merge commit for release branches.

**Mandatory skills before merging:**

| Skill              | When                                            |
| ------------------ | ----------------------------------------------- |
| `/review`          | Every PR                                        |
| `/cso`             | Any PR touching auth / payments / RLS / secrets |
| `/plan-eng-review` | New table, API client, or architectural change  |
| `/investigate`     | Any bugfix PR (root cause documented)           |

---

## 3. CI Workflows

Located in `.github/workflows/`:

| Workflow         | Trigger                                | What it does                                |
| ---------------- | -------------------------------------- | ------------------------------------------- |
| `flutter-ci.yml` | push/PR to `main` touching `mobile/**` | pub get, analyze, test, build APK (debug)   |
| `quality.yml`    | push/PR to `main`                      | flutter analyze + test coverage gate (≥70%) |
| `security.yml`   | push/PR to `main`                      | gitleaks secret scan + dependency audit     |

**Local pre-commit hooks** (`.pre-commit-config.yaml`): trailing whitespace, YAML, large files, private key detection, Flutter format + analyze.

---

## 4. Environments

| Environment    | Supabase project      | Flutter build                             | GitHub Environment |
| -------------- | --------------------- | ----------------------------------------- | ------------------ |
| **Develop**    | `dev` project ref     | `--dart-define-from-file=.env.dev`        | `Develop`          |
| **Staging**    | `staging` project ref | `--dart-define-from-file=.env.staging`    | `Staging`          |
| **Production** | `prod` project ref    | `--dart-define-from-file=.env.production` | `Production`       |

Flutter env vars (`mobile/.env.<env>`):

- `SUPABASE_URL` — Environment Variable per env
- `SUPABASE_ANON_KEY` — Environment Secret per env
- `TURNSTILE_SITE_KEY` — Repository Variable (same across envs)

---

## 5. Secrets Management

**Rule: no secret ever touches this repo.**

| Secret category       | Where it lives                                                      |
| --------------------- | ------------------------------------------------------------------- |
| Flutter build secrets | `mobile/.env.<env>` — gitignored; set in GitHub Environment secrets |
| Supabase CLI token    | `SUPABASE_API_KEY` GitHub Repository Secret                         |
| Edge Function secrets | `supabase secrets set KEY=value` — never in repo                    |
| Sentry DSN            | GitHub Environment secret → `SENTRY_DSN` dart-define                |

**If a secret is accidentally committed:** rotate immediately, remove from history with `git filter-repo`, notify the team.

---

## 6. Flutter Commands

Run from `mobile/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter test --coverage
flutter build apk --flavor dev
flutter build apk --flavor staging
flutter build apk --flavor production
```

---

## 7. Supabase Commands

```bash
supabase start                          # Start local Supabase (Docker)
supabase db push --project-ref <ref>    # Apply migrations to remote
supabase functions serve                # Serve Edge Functions locally
supabase functions deploy <name>        # Deploy a specific Edge Function
supabase secrets set KEY=value          # Set Edge Function secret
```

**Migration naming:** `RS-XXX_description_in_snake_case.sql`. IDs ≥ RS-200 (post-baseline).

---

## 8. Deploy Procedure

1. Merge PR to `main` — CI runs automatically.
2. For Edge Functions: `supabase functions deploy <name> --project-ref <ref>`.
3. For mobile: APK builds are artifacts; production release goes through Google Play.
4. For DB migrations: `supabase db push --project-ref <prod-ref>` — run only after staging validation.

---

## 9. Oncall / Incidents

- **Sentry** (Sprint 5): primary alert source for mobile crashes and Edge Function errors.
- Incident response: create a `fix/RS-XXX-*` branch, `/investigate` to document root cause, PR with test that reproduces.

---

## 10. Definition of Done

- [ ] Code passes `flutter analyze`
- [ ] New/modified logic has unit/widget tests
- [ ] No regression in existing tests (`flutter test`)
- [ ] Coverage does not drop below 70% on new code
- [ ] PII (cédulas, nombres, teléfonos, plates) is never logged
- [ ] No secrets committed
- [ ] PR template filled out
