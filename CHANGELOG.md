# Fork changelog

## 0.1.0 — 2026-09-08

First versioned baseline of the `alooooooone/SwipeActions` fork. These versions
belong to this fork, independently of upstream releases.

- Includes customizable action/mask corner style and non-negative action widths.
- Prevents non-finite spring velocity when a drag returns to zero displacement.
- Ignores velocity samples with non-positive or non-finite elapsed time.
- Uses the configured close spring parameters when closing actions.
- Adds regression tests for spring velocity normalization.

Apps should use this fork's URL with an exact version and commit Package.resolved.
Local overrides are for development only. Review upstream updates on a branch
before publishing a new fork version; do not move existing release tags.

The upstream MIT license and attribution remain in the source and repository.
