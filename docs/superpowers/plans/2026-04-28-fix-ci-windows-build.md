# Fix CI Windows Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the scheduled GitHub Actions Windows 32-bit build reach configure reliably, survive upstream VS2026 redist updates, and fail earlier with actionable diagnostics when upstream changes again.

**Architecture:** Keep this repository's downstream override small: only patch Windows-specific i686 settings that upstream Zen Browser does not provide. Let upstream `configs/common/mozconfig` own release, optimization, telemetry, debug, and packaging defaults so removed configure options do not break the downstream build when upstream Firefox/Zen changes.

**Tech Stack:** GitHub Actions, Bash, Mozilla/Zen `mozconfig`, Surfer, `mach configure`, MSVC VS2026 cross toolchain, Wine, npm.

---

## Current Failure Summary

Latest failed run checked: `https://github.com/teppyboy/zen-32bit/actions/runs/25026969937`.

Primary fatal error in latest run:

```text
mozbuild.configure.options.InvalidOptionError: Unknown option: --enable-av1
```

Secondary blocker already found in earlier run:

```text
mozbuild.configure.ConfigureError: Invalid Win32 Redist directory: /home/runner/win-cross/vs2026/VC/Redist/MSVC/14.38.33135/x86/Microsoft.VC143.CRT
```

Known local fixes already staged in worktree but not committed:

```text
mode 100755: ubuntu-windows/build-instrumented.sh
mode 100755: ubuntu-windows/cleanup.sh
mode 100755: ubuntu-windows/init/nodejs.sh
mode 100755: ubuntu-windows/init/rust.sh
mode 100755: ubuntu-windows/init/system.sh
mode 100755: ubuntu-windows/init/windows.sh
mode 100755: ubuntu-windows/init/x86.sh
dynamic WIN32_REDIST_DIR in desktop/configs/windows/mozconfig
MSVC redist preflight in ubuntu-windows/init/windows.sh
```

Upstream Zen differences that matter:

- Upstream `configs/common/mozconfig` no longer uses downstream-only options like `--enable-av1`, `--enable-raw`, `--enable-webrtc`, `--enable-wasm-avx`, `--enable-jemalloc`, `--enable-hardening`, `--enable-strip`, `--enable-install-strip`, or custom `/O2 /clang:-O3 ...` optimize flags.
- Upstream release builds set `ZEN_RELEASE=1` and let common mozconfig own release/debug/test/LTO/telemetry/signing flags.
- Upstream reads Windows Rust crate version dynamically from `build/windows/.windows-rs-version`; local `ubuntu-windows/init.sh` hardcodes `windows-0.62.2`.
- Upstream runs `dos2unix configs/windows/mozconfig` before build; local workflow does not.
- Upstream VS2026 redist currently installs `VC/Redist/MSVC/14.50.35710/.../Microsoft.VC145.CRT`; local committed config still referenced `14.38.33135/.../Microsoft.VC143.CRT` before the local dynamic fix.

## File Map

- Modify: `desktop/configs/windows/mozconfig`
  - Responsibility: downstream Windows i686 cross-build overrides only.
  - Remove invalid and duplicate configure options that upstream common mozconfig owns.
  - Keep dynamic `WIN32_REDIST_DIR` and i686 target.

- Modify: `ubuntu-windows/init.sh`
  - Responsibility: clone/init upstream desktop repo and append local bootstrap-only mozconfig exports.
  - Replace hardcoded `windows-0.62.2` with upstream `.windows-rs-version` detection.
  - Prefer upstream-compatible `npm ci` only when lockfile exists; otherwise keep `npm install`.

- Modify: `ubuntu-windows/init/windows.sh`
  - Responsibility: install Windows cross dependencies and validate MSVC/Wine layout.
  - Keep dynamic redist preflight.
  - Use `wine` path compatible with upstream, while preserving local `wine64` symlink only as fallback if needed.

- Modify: `ubuntu-windows/patch.sh`
  - Responsibility: copy downstream mozconfig into the cloned upstream tree.
  - Run `dos2unix` on copied mozconfig when available so line endings cannot break configure.
  - Print local `ac_add_options` for CI diagnostics.

- Modify: `.github/workflows/release.yml`
  - Responsibility: CI orchestration.
  - Use `bash` invocation for scripts as belt-and-suspenders even though execute bits are fixed.
  - Keep cache key but include VS config hash or version suffix only if dynamic redist validation exposes stale cache issues.

- Preserve mode changes on all tracked shell scripts.
  - Responsibility: prevent direct script execution from failing with exit code `126`.

---

### Task 1: Preserve Executable Bits

**Files:**
- Modify mode: `ubuntu-windows/build-instrumented.sh`
- Modify mode: `ubuntu-windows/cleanup.sh`
- Modify mode: `ubuntu-windows/init/nodejs.sh`
- Modify mode: `ubuntu-windows/init/rust.sh`
- Modify mode: `ubuntu-windows/init/system.sh`
- Modify mode: `ubuntu-windows/init/windows.sh`
- Modify mode: `ubuntu-windows/init/x86.sh`

- [ ] **Step 1: Verify all tracked shell scripts are executable in git index**

Run:

```bash
git ls-files --stage -- "*.sh"
```

Expected: every tracked `.sh` line starts with `100755`.

- [ ] **Step 2: Fix any missing executable bit**

Run only if Step 1 shows any `100644` shell scripts:

```bash
git update-index --chmod=+x -- ubuntu-windows/*.sh ubuntu-windows/init/*.sh
```

- [ ] **Step 3: Verify execute-bit fix**

Run:

```bash
git ls-files --stage -- "*.sh"
```

Expected: no `100644` entries for tracked shell scripts.

- [ ] **Step 4: Commit executable bits with related CI fixes later**

Do not create a standalone commit yet. Commit after Task 5 so CI receives all blockers together.

---

### Task 2: Reduce Windows Mozconfig To Supported Downstream Overrides

**Files:**
- Modify: `desktop/configs/windows/mozconfig`

- [ ] **Step 1: Replace the file with minimal upstream-aligned i686 config**

Set `desktop/configs/windows/mozconfig` to this exact content:

```bash
# Downstream Windows 32-bit cross-build overrides for Zen Browser.
# Keep this file small: upstream configs/common/mozconfig owns release,
# optimization, telemetry, debug, test, package, and signing defaults.

if test "$ZEN_CROSS_COMPILING"; then
  export WINSYSROOT="$(echo ~)/win-cross/vs2026"

  export WINE="$(echo ~)/win-cross/wine/bin/wine"
  export WINEARCH=win32
  export WINEDEBUG=-all

  export MOZ_STUB_INSTALLER=1
  export MOZ_PKG_FORMAT=TAR

  export CROSS_BUILD=1
  CROSS_COMPILE=1

  WIN32_REDIST_DIR="$(ls -d "$WINSYSROOT"/VC/Redist/MSVC/*/x86/Microsoft.VC*.CRT 2>/dev/null | sort -V | tail -n1)"
  if test -z "$WIN32_REDIST_DIR" -o ! -d "$WIN32_REDIST_DIR"; then
    echo "ERROR: Could not resolve WIN32_REDIST_DIR under $WINSYSROOT/VC/Redist/MSVC" 1>&2
    exit 1
  fi
  export WIN32_REDIST_DIR
fi

# Build Zen only.
ac_add_options --enable-application=browser
ac_add_options --disable-artifact-builds

# 32-bit Windows target.
ac_add_options --target=i686-pc-windows-msvc

# Keep only options still present in upstream Zen configs or required by i686.
ac_add_options --enable-jxl
ac_add_options --with-unsigned-addon-scopes=app,system
ac_add_options --disable-sandbox
ac_add_options --without-wasm-sandboxed-libraries
ac_add_options --disable-maintenance-service
ac_add_options --disable-bits-download

if test "$ZEN_CROSS_COMPILING"; then
  if test "$ZEN_GA_GENERATE_PROFILE"; then
    mk_add_options "export MOZ_AUTOMATION_PACKAGE_GENERATED_SOURCES=0"
    ac_add_options --enable-profile-generate=cross
  elif test -z "$ZEN_GA_DISABLE_PGO"; then
    ac_add_options --enable-profile-use=cross
    ac_add_options --with-pgo-profile-path=$(echo ~)/artifact/merged.profdata
    ac_add_options --with-pgo-jarlog=$(echo ~)/artifact/en-US.log
  fi
fi
```

- [ ] **Step 2: Confirm invalid options are gone**

Run:

```bash
rg --line-number "--enable-av1|--enable-raw|--enable-webrtc|--enable-wasm-avx|--enable-jemalloc|--enable-hardening|--enable-strip|--enable-install-strip|--enable-geckodriver|--enable-optimize=" desktop/configs/windows/mozconfig
```

Expected: no matches.

- [ ] **Step 3: Confirm required downstream options remain**

Run:

```bash
rg --line-number "i686-pc-windows-msvc|WIN32_REDIST_DIR|enable-profile-generate|enable-profile-use|without-wasm-sandboxed-libraries" desktop/configs/windows/mozconfig
```

Expected: matches for each required phrase.

- [ ] **Step 4: Reconsider EME only after configure passes**

Do not add `ac_add_options --enable-eme=widevine,wmfcdm` in this task. If product requirements need DRM later, add it in a separate CI-tested change after basic configure/build works.

---

### Task 3: Make Windows Rust Crate Version Dynamic

**Files:**
- Modify: `ubuntu-windows/init.sh`

- [ ] **Step 1: Replace npm install/init block with lockfile-aware install**

Replace lines currently equivalent to:

```bash
echo "Initializing repository..."
npm install
npm run init
mkdir -p engine/
```

with:

```bash
echo "Initializing repository..."
if [ -f package-lock.json ]; then
    npm ci
else
    npm install
fi
npm run init
mkdir -p engine/
```

- [ ] **Step 2: Replace hardcoded Windows Rust export**

Replace lines currently equivalent to:

```bash
echo "" >> ./configs/common/mozconfig
echo "export MOZ_WINDOWS_RS_DIR=$(pwd)/windows-0.62.2" >> ./configs/common/mozconfig
```

with:

```bash
WINDOWS_RS_VERSION=$(cat build/windows/.windows-rs-version)
echo "" >> ./configs/common/mozconfig
echo "export MOZ_WINDOWS_RS_DIR=$(pwd)/windows-$WINDOWS_RS_VERSION" >> ./configs/common/mozconfig
```

- [ ] **Step 3: Verify no hardcoded Windows Rust version remains**

Run:

```bash
rg --line-number "windows-0\.62\.2|MOZ_WINDOWS_RS_DIR" ubuntu-windows/init.sh
```

Expected: one match for `MOZ_WINDOWS_RS_DIR`, zero matches for `windows-0.62.2`.

---

### Task 4: Harden Windows Toolchain Preflight

**Files:**
- Modify: `ubuntu-windows/init/windows.sh`

- [ ] **Step 1: Keep redist validation, align Wine with upstream**

Ensure the file contains this MSVC validation block after `get_vs.py`:

```bash
echo "Validating installed MSVC redist/toolset paths..."
redist_root=~/win-cross/vs2026/VC/Redist/MSVC
tools_root=~/win-cross/vs2026/VC/Tools/MSVC

echo "Detected MSVC tool versions:"
ls -1 "$tools_root" || true

echo "Detected MSVC redist versions:"
ls -1 "$redist_root" || true

latest_redist_dir=$(ls -d "$redist_root"/*/x86/Microsoft.VC*.CRT 2>/dev/null | sort -V | tail -n1)
if [ -z "$latest_redist_dir" ] || [ ! -d "$latest_redist_dir" ]; then
    echo "ERROR: Could not find x86 MSVC CRT redist directory under $redist_root" 1>&2
    exit 1
fi

echo "Using Win32 redist directory: $latest_redist_dir"
```

- [ ] **Step 2: Keep wine64 symlink only as compatibility fallback**

Leave this block in place because local mozconfig used `wine64` previously and cached toolchains may still contain scripts that expect it:

```bash
if [ ! -x ~/win-cross/wine/bin/wine64 ]; then
    echo "Workaround wine64 binary..."
    ln -sf ~/win-cross/wine/bin/wine ~/win-cross/wine/bin/wine64
    chmod +x ~/win-cross/wine/bin/wine64
fi
```

Do not point `desktop/configs/windows/mozconfig` at `wine64`; use upstream-compatible `wine` there.

- [ ] **Step 3: Verify validation text exists**

Run:

```bash
rg --line-number "Validating installed MSVC|latest_redist_dir|Microsoft\.VC\*\.CRT|wine64" ubuntu-windows/init/windows.sh desktop/configs/windows/mozconfig
```

Expected: MSVC validation in `ubuntu-windows/init/windows.sh`, `wine64` only in `ubuntu-windows/init/windows.sh`, not in `desktop/configs/windows/mozconfig`.

---

### Task 5: Add Patch Diagnostics And Line Ending Normalization

**Files:**
- Modify: `ubuntu-windows/patch.sh`

- [ ] **Step 1: Replace patch script content**

Set `ubuntu-windows/patch.sh` to this exact content:

```bash
#!/usr/bin/env bash

set -e

echo "Patching mozconfigs..."
cd zen-browser/desktop
cp -f ../../desktop/configs/windows/mozconfig ./configs/windows/mozconfig

if command -v dos2unix >/dev/null 2>&1; then
    dos2unix ./configs/windows/mozconfig
fi

echo "Applied Windows mozconfig options:"
grep -n "ac_add_options" ./configs/windows/mozconfig || true
```

- [ ] **Step 2: Verify script syntax**

Run:

```bash
bash -n ubuntu-windows/patch.sh
```

Expected: exit code `0`, no output.

- [ ] **Step 3: Verify diagnostics include downstream options**

Run:

```bash
rg --line-number "dos2unix|Applied Windows mozconfig options|grep -n" ubuntu-windows/patch.sh
```

Expected: matches for all three diagnostics.

---

### Task 6: Make Workflow Invocation Robust

**Files:**
- Modify: `.github/workflows/release.yml`

- [ ] **Step 1: Use explicit Bash for repository scripts**

Change the `Initialize dependencies and repository` step from:

```yaml
run: |
  ./ubuntu-windows/init.sh
  ./ubuntu-windows/patch.sh
```

to:

```yaml
run: |
  bash ./ubuntu-windows/init.sh
  bash ./ubuntu-windows/patch.sh
```

Change the `Build instrumented binary (Stage 1 PGO)` step from:

```yaml
run: ./ubuntu-windows/build-instrumented.sh
```

to:

```yaml
run: bash ./ubuntu-windows/build-instrumented.sh
```

- [ ] **Step 2: Apply the same pattern to release job script calls**

Search:

```bash
rg --line-number "run: ./ubuntu-windows|./ubuntu-windows/" .github/workflows/release.yml
```

For every local shell script invocation, use `bash ./ubuntu-windows/<script>.sh` unless it is inside a Windows PowerShell step.

- [ ] **Step 3: Keep execute bits anyway**

Do not remove executable-bit fixes. Bash invocation prevents future accidental mode regressions from blocking CI; execute bits keep local direct execution working.

---

### Task 7: Verify Locally Before Pushing

**Files:**
- Verify only.

- [ ] **Step 1: Check Bash syntax for all local scripts**

Run:

```bash
for f in ubuntu-windows/*.sh ubuntu-windows/init/*.sh; do bash -n "$f"; done
```

Expected: exit code `0`, no syntax output.

- [ ] **Step 2: Check tracked modes**

Run:

```bash
git ls-files --stage -- "*.sh"
```

Expected: every tracked `.sh` entry starts with `100755`.

- [ ] **Step 3: Check removed configure options**

Run:

```bash
rg --line-number "--enable-av1|--enable-raw|--enable-webrtc|--enable-wasm-avx|--enable-jemalloc|--enable-hardening|--enable-strip|--enable-install-strip|--enable-geckodriver|--enable-optimize=" desktop/configs/windows/mozconfig
```

Expected: no matches.

- [ ] **Step 4: Check required configure options**

Run:

```bash
rg --line-number "target=i686|WIN32_REDIST_DIR|enable-profile-generate|enable-profile-use|disable-sandbox|without-wasm-sandboxed-libraries" desktop/configs/windows/mozconfig
```

Expected: matches for all required downstream options.

- [ ] **Step 5: Review diff**

Run:

```bash
git diff --stat
git diff -- desktop/configs/windows/mozconfig ubuntu-windows/init.sh ubuntu-windows/init/windows.sh ubuntu-windows/patch.sh .github/workflows/release.yml
```

Expected: diff only contains the planned changes plus existing script mode changes. Do not include unrelated `.claude/` or `.memory/` files.

---

### Task 8: Commit And Trigger CI

**Files:**
- Commit planned changes only.

- [ ] **Step 1: Stage only relevant files**

Run:

```bash
git add desktop/configs/windows/mozconfig ubuntu-windows/init.sh ubuntu-windows/init/windows.sh ubuntu-windows/patch.sh .github/workflows/release.yml ubuntu-windows/*.sh ubuntu-windows/init/*.sh
```

Expected: relevant files staged; `.claude/` and `.memory/` remain untracked.

- [ ] **Step 2: Verify staged diff**

Run:

```bash
git diff --cached --stat
git diff --cached --name-status
```

Expected: only planned files and mode changes are staged.

- [ ] **Step 3: Commit**

Run:

```bash
git commit -m "fix: align Windows CI mozconfig with upstream"
```

Expected: commit succeeds.

- [ ] **Step 4: Push and trigger CI when user approves**

Run only with explicit user approval:

```bash
git push
```

Expected: GitHub Actions `Create File Release` starts on `master` push, or manually run workflow if pushing to a branch.

---

### Task 9: Inspect Next CI Failure Or Success

**Files:**
- Verify only.

- [ ] **Step 1: Watch latest run**

Run:

```bash
gh run list --workflow "Create File Release" --limit 5
```

Expected: newest run appears for the pushed commit.

- [ ] **Step 2: If it fails, inspect failed job log**

Run:

```bash
gh run view <run-id> --json jobs,conclusion,headSha,url
gh run view <run-id> --job <job-id> --log-failed
```

Expected if this plan fixed current blockers: no `Unknown option: --enable-av1`, no `Invalid Win32 Redist directory`, no `Permission denied` on local scripts.

- [ ] **Step 3: If configure still fails on a different option, remove only that unsupported downstream option**

Use this decision rule:

```text
If option is not present in upstream dev configs and is not required for i686 target, remove it from desktop/configs/windows/mozconfig.
If option is required for i686 target, find current upstream Firefox configure spelling before replacing it.
Do not re-add optimization bundles from old Mercury config.
```

---

## Self-Review

- Spec coverage: plan uses `gh` findings, fixes latest CI failure, includes earlier permission and redist blockers, compares upstream Zen Browser, and defines upstream-aligned changes to reduce future breakage.
- Placeholder scan: no TBD/TODO/fill-later steps; every edit step includes exact file path and replacement content or command.
- Type/path consistency: all paths match repository layout observed locally: `desktop/configs/windows/mozconfig`, `ubuntu-windows/init.sh`, `ubuntu-windows/init/windows.sh`, `ubuntu-windows/patch.sh`, `.github/workflows/release.yml`.
- Risk left intentionally: 32-bit i686 support is downstream-only and not covered by upstream Zen. The plan minimizes custom config surface but cannot guarantee upstream Firefox still supports every required i686 dependency until CI reaches configure/build.
