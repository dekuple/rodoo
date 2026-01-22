---
name: release
description: Release the Rodoo gem to RubyGems with automatic versioning and changelog
disable-model-invocation: true
---

# Release Rodoo gem

## Current state

Last tag: !`git describe --tags --abbrev=0 2>/dev/null`
Current branch: !`git rev-parse --abbrev-ref HEAD`
Uncommitted changes: !`git status --short`

## Instructions

Follow these steps precisely to release the gem.

### 1. Validate prerequisites

- Ensure you're on the `develop` branch
- Ensure working directory is clean (no uncommitted changes)
- Run `rake` to verify tests and linter pass

If any check fails, stop and inform the user.

### 2. Analyze commits since last release

Run: `git log $(git describe --tags --abbrev=0)..HEAD --oneline`

Categorize each commit:
- **Added**: New features (commits starting with "Add")
- **Changed**: Changes to existing functionality
- **Fixed**: Bug fixes (commits starting with "Fix")
- **Removed**: Removed features

Ignore commits that are:
- Version bumps ("Bump version")
- Merge commits
- Gemfile.lock updates only

### 3. Determine version bump

Based on the commits, determine the version bump using semver:

- **MAJOR** (X.0.0): Breaking changes (look for "BREAKING", "breaking change", major API changes)
- **MINOR** (0.X.0): New features, new models, new API methods (most "Add" commits)
- **PATCH** (0.0.X): Bug fixes, documentation, minor tweaks

Read current version from `lib/rodoo/version.rb` and calculate the new version.

### 4. Update CHANGELOG.md

Read `CHANGELOG.md`. Update the `## [Unreleased]` section:

1. Replace `## [Unreleased]` with `## [Unreleased]` followed by a blank line and `## [NEW_VERSION] - YYYY-MM-DD`
2. Under the new version heading, add categorized entries:

```markdown
## [Unreleased]

## [X.Y.Z] - 2026-01-22

### Added
- Description of new feature

### Changed
- Description of change

### Fixed
- Description of fix
```

Only include sections that have entries. Write concise, user-facing descriptions (not raw commit messages).

### 5. Update version.rb

Edit `lib/rodoo/version.rb` to set the new VERSION.

### 6. Update Gemfile.lock

Run: `bundle install`

### 7. Commit the release

```bash
git add lib/rodoo/version.rb CHANGELOG.md Gemfile.lock
git commit -m "Bump version to X.Y.Z"
```

### 8. Push develop branch

```bash
git push origin develop
```

### 9. Merge to main

```bash
git checkout main
git pull origin main
git merge develop
```

### 10. Push main branch

```bash
git push origin main
```

### 11. Release to RubyGems

Run: `rake release`

This will:
- Build the gem
- Create and push the git tag
- Push to RubyGems

**Note**: If RubyGems requires authentication (one-time code), the user will need to enter it in the terminal.

### 12. Return to develop

```bash
git checkout develop
```

### 13. Summary

Report to the user:
- Previous version → New version
- Changelog entries added
- RubyGems URL: https://rubygems.org/gems/rodoo
