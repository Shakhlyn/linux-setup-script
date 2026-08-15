# AGENTS.md - A modular Linux dev-environment installer

Guidance for AI coding agents (Codex CLI, Claude, etc.) working in this repo.
This is a **modular Linux dev-environment installer** targeting Ubuntu,
Lubuntu, Pop!_OS, and Fedora. `installer.sh` is the entry point and
orchestrates a set of standalone module scripts, all of which share common
logging and utility libraries.

Read this whole file before writing or editing any script.

---

## 1. Design philosophy

This project has an established shape (logger, idempotency checks, distro
dispatch, retry loops), and agents should default to it — but the goal is
**the best version of this codebase**, not a museum of its current state.

- **New scripts:** follow the established conventions in this doc, and where
  you see a genuinely better approach (clearer error handling, less
  duplication, a safer check), use it and explain the change. Don't silently
  invent a new style out of preference — but don't hold back a real
  improvement just to match an old pattern either.
- **Polishing existing scripts:** when asked to clean up or refactor a
  script, actively look for the best possible implementation — fix
  inconsistencies, tighten error handling, remove dead code, improve
  naming — not just a light pass that preserves whatever was already there.
- If a "better way" would ripple across multiple files (e.g. changing how
  `error_exit` is used inside modules — see §6), call that out explicitly
  and either do the ripple fix or leave a clear TODO, rather than
  introducing a one-off inconsistency in a single file.

In short: match the codebase's *conventions* (naming, logging, structure),
but not its *mistakes*. Flag anything you deliberately deviate from and why.

---

## 2. Repository structure

```
.
├── installer.sh              # Entry point — sources utils, detects distro, runs modules
├── utils/
│   ├── lib-logger.sh          # Logging primitives (log_info, log_error, etc.)
│   └── utils.sh               # Shared helpers (is_installed, install_packages, distro detection...)
├── modules/                   # One script per tool/program (docker.sh, vim.sh, ...)
│   └── docker.sh
└── logs/                      # Generated at runtime — do not commit
```

> If the real module directory has a different name, correct this section
> so future agents don't guess wrong paths — keep this doc in sync with
> reality as the project grows.

Every module script should be runnable both standalone (for debugging) and
via `installer.sh` (for the full run).

---

## 3. Distro support status

Both **Ubuntu/Pop!_OS/Lubuntu and Fedora are first-class, actively
supported targets**.

Implications for agents:
- When adding a **new** module, implement both `_ubuntu` and `_fedora`
  branches from the start — don't defer Fedora to "later."
- When polishing an **existing** Ubuntu-only module, retrofitting it with a
  `_fedora` branch is in scope by default — don't leave it Ubuntu-only
  unless explicitly told to.
- If a Fedora branch genuinely can't be verified in the current environment,
  say so explicitly in the response (not just a code comment) so it gets a
  real test pass before being trusted.

---

## 4. Core conventions

### 4.1 Sourcing
Every script that logs or checks installation state starts with:

```bash
#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

source ./utils/lib-logger.sh
source ./utils/utils.sh   # only if the script needs is_installed / install_packages / distro helpers
```

`set -uo pipefail` is standard across the project. Add it to any script
that's missing it as part of a polish pass.

### 4.2 Logging
Never use raw `echo`/`printf` for status output — always go through the
logger:

| Function        | Purpose                                                        |
|-----------------|------------------------------------------------------------------|
| `log_info`      | Progress / narration                                            |
| `log_success`   | A step completed successfully                                   |
| `log_confirm`   | Something was already in the desired state (idempotency no-op)  |
| `log_warn`      | Non-fatal issue, execution continues                             |
| `log_error`     | A step failed but the script may continue, or is about to exit  |
| `log_fail`      | A whole module failed (used by `run_module`)                     |

`error_exit "message"` logs via `log_error` and exits 1 — reserve it for
unrecoverable **bootstrap** failures (e.g. can't create the logs directory,
unsupported distro at the top-level detection step). Don't call `exit`
directly anywhere else.

### 4.3 Idempotency first
Every install/config action checks current state before acting, and uses
`log_confirm` (not `log_info`) when skipping because it's already done.

`is_installed` is the single source of truth for "is X installed" — it
checks PATH, `dpkg`, `snap`, `flatpak`, and `pip` in order. Extend it rather
than reimplementing ad hoc checks (`which foo`, custom `dpkg` calls) in a
new module.

For non-package state (repos, group membership, config files), mirror the
same shape:
```bash
if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
    log_confirm "Docker APT repository already exists. Skipping."
    return 0
fi
```

### 4.4 Distro dispatch pattern
Any behavior that differs by distro follows this three-function shape —
`<action>_ubuntu`, `<action>_fedora`, and a bare `<action>` dispatcher:

```bash
<action>_ubuntu() { ... }
<action>_fedora() { ... }

<action>() {
    case "${DISTRO:-}" in
        ubuntu|lubuntu|pop)
            <action>_ubuntu
            ;;
        fedora)
            <action>_fedora
            ;;
        *)
            log_error "<action>: Unsupported distribution '${DISTRO:-unset}'."
            return 1
            ;;
    esac
}
```

**Skip the split for steps that are genuinely identical across distros — don't
force a 3-function shape where there's no actual variance.**

Package installation goes through the existing `install_packages` /
`apt_install_multiple` / `dnf_install_multiple` wrappers in `utils.sh`, not
raw `apt`/`dnf` calls, so retry/logging/skip-if-installed behavior stays
consistent.

### 4.5 Network calls get retries
Anything hitting the network (package index updates, curl downloads) uses
the retry-with-backoff shape from `update_apt`/`update_dnf`:

```bash
local retries=5
local delay=5
local count=0

while ! <network_command>; do
    count=$((count + 1))
    if [[ $count -ge $retries ]]; then
        error_exit "<command> failed after $retries attempts."
    fi
    log_error "<command> failed (attempt $count/$retries). Retrying in ${delay}s..."
    sleep "$delay"
done
```

### 4.6 Module orchestration
`installer.sh` calls each module through `run_module`:

```bash
run_module "Docker" install_docker_suite
```

Module entry-point functions (e.g. `install_docker_suite`) must:
- Return 0 on success, non-zero on failure — `run_module` only inspects
  `$?`, nothing else.
- Chain internal steps with `|| return 1` rather than relying on `set -e`,
  so failure points stay explicit and `run_module` can capture status
  reliably.
- **Not** call `script_divider` directly — `run_module` owns that.

### 4.7 Naming & style
- Public functions: `snake_case`, verb-first (`install_docker_suite`,
  `set_docker_repo`, `verify_docker`).
- Internal/private helpers not meant to be called from outside the file: `_`
  prefix (e.g. `_is_full_vim_installed`).
- Always `local` your variables inside functions.
- Quote all variable expansions (`"$var"`, `"${arr[@]}"`).
- Prefer `[[ ]]` over `[ ]`.
- Section headers use the box-comment style already in the codebase:

```bash
# ─────────────────────────────────────────────────────────────────────────────
# function_name
# One-line description of what it does.
# ─────────────────────────────────────────────────────────────────────────────
```
Add one above every new public function.

---

## 5. Adding a new module (checklist)

1. `#!/bin/bash`, `set -uo pipefail`, `IFS=$'\n\t'`, source `lib-logger.sh` +
   `utils.sh`.
2. Idempotency guard at the top of the main entry function.
3. `_ubuntu` / `_fedora` / dispatcher split for every step that actually
   varies by distro — implement **both** branches, not just Ubuntu.
4. Package installs go through `install_packages`, never raw `apt`/`dnf`.
5. Network/risky steps get retry logic or at minimum explicit exit-code
   checks with `log_error`.
6. A `verify_<tool>` step that smoke-tests the install and reports via
   `log_confirm`/`log_error`.
7. One top-level `install_<tool>_suite` function that `installer.sh` passes
   to `run_module`.
8. Every step returns a real exit code — no swallowed errors.

## 5b. Polishing an existing module (checklist)

Treat this as a real refactor pass, not a formatting pass:

1. Does it have `set -uo pipefail`? Add it if missing.
2. Does every state-changing step have an idempotency check? Add one if
   missing.
3. Is there a Fedora branch? If not and the tool is realistically
   installable on Fedora, add `_fedora` alongside `_ubuntu`.
4. Any raw `apt`/`dnf`/`curl` calls that should go through the shared
   wrappers? Replace them.
5. Any `exit`/`error_exit` calls inside module-internal functions that
   should be `log_error; return 1` instead (see §6)? Fix them.
6. Any duplicated logic that now exists in `utils.sh` and can be replaced by
   a shared helper? Replace it and note the dedup in your summary.

---

## 6. Known inconsistency to watch for

`error_exit` currently gets called both from top-level bootstrap code
(`generate_log_files`) **and** from inside dispatcher functions like
`install_packages`/`update_packages`. That's fine while execution is
single-threaded and linear, but once more modules run through `run_module`,
an `error_exit` fired from inside a module kills the *entire installer run*
instead of just failing that one module.

Default going forward: inside module-internal functions, use
`log_error "..."; return 1` and let `run_module`/`installer.sh` decide
whether to halt. Reserve `error_exit` for genuine bootstrap failures
(logging setup, distro detection, unsupported distro at the very start).
When polishing a script, fix instances of this if you find them.

---

## 7. Things to avoid

- Raw `echo`/`printf` for user-facing status — always use the logger.
- Reimplementing "is this installed" checks instead of extending
  `is_installed`.
- Calling `exit`/`error_exit` from inside a module's internal functions
  (see §6).
- Hardcoding `sudo apt`/`sudo dnf` instead of going through
  `install_packages`/`update_packages`.
- One-off logging colors/levels — extend `lib-logger.sh` centrally instead.
- Bash 5+-only syntax unless already used elsewhere — target compatibility
  with the Bash shipped on Ubuntu 20.04+ and current Fedora.
- Leaving a new module Ubuntu-only "for now" — see §3.

---

## 8. Testing / verification expectations

There's no formal test suite yet. Before considering a script done:
- `bash -n <script>.sh` at minimum (syntax check).
- Run `shellcheck` if available; address warnings unless they conflict with
  an established pattern (e.g. intentional word-splitting) — note any
  deliberate suppression with a comment.
- Manually trace the idempotent path (what happens on a second run) — safe
  re-runs are a core requirement of this project, not a nice-to-have.
- For Fedora branches specifically: if you can't run them locally, say so
  explicitly rather than presenting untested `dnf` logic as verified.

---

## 9. Definition of done

A change is done when:
- It follows §4's conventions (or explicitly improves on them per §1, with
  the change called out).
- Both distro branches exist and are at least syntax-checked, ideally
  smoke-tested.
- Logging uses the correct level for every outcome (success vs. confirm vs.
  warn vs. error vs. fail).
- Idempotency is verified by reasoning through a second run.
- Nothing calls `exit`/`error_exit` from inside module internals.

---

## 10. Notes for future agents

- Keep this file in sync with reality — if you introduce a new shared
  wrapper, logging level, or convention, update the relevant section here in
  the same change.
- Prefer small, reviewable diffs per module over broad multi-file refactors,
  unless explicitly asked for a sweep (e.g. "retrofit Fedora support across
  all modules").
---

## 11. Git & Commit Conventions

- Conventional Commits format: `feat:`, `fix:`, `refactor:`, `chore:`,
  `style:`, `docs:`, `perf:`.
- Small, atomic commits over large sweeping ones — one logical change per
  commit.
- It is suggested that you not touch git commands.

---

## 12. Working Agreement for the Agent

- **Plan before large changes.** For anything touching more than 2–3 files,
  state a short plan first (files to touch, approach) before writing code.
- **Prefer editing over adding.** Before creating a new component/util,
  check if an existing one can be extended.
- **No silent scope creep.** If a task implies adding a new dependency,
  changing the folder structure, or deviating from this file, say so
  explicitly and ask, rather than doing it quietly.
- **Explain non-obvious decisions** in a short code comment, not in a
  separate essay — the code should be self-documenting where possible.
- **Ask when ambiguous**, but only when the ambiguity would meaningfully
  change the output — don't stall on things with an obvious sensible default.

---
