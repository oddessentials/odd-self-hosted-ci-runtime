// Commitlint configuration for OSCR
// Enforces Conventional Commits: https://www.conventionalcommits.org/
//
// Valid commit types:
//   feat:     New feature (triggers minor version bump)
//   fix:      Bug fix (triggers patch version bump)
//   docs:     Documentation only changes
//   style:    Code style changes (formatting, whitespace)
//   refactor: Code refactoring (no feature or fix)
//   perf:     Performance improvements
//   test:     Adding or updating tests
//   build:    Build system or external dependencies
//   ci:       CI configuration changes
//   chore:    Other changes (maintenance, tooling)
//   revert:   Revert a previous commit
//
// Breaking changes:
//   Add "!" after type or include "BREAKING CHANGE:" in footer
//   Example: feat!: remove deprecated API
//   Triggers major version bump

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Enforce lowercase for type
    'type-case': [2, 'always', 'lower-case'],
    // Allow proper nouns and acronyms in subject (e.g., "Docker Hub", "CI")
    // Conventional Commits spec does not mandate lowercase subjects
    'subject-case': [0],
    // No period at end of subject
    'subject-full-stop': [2, 'never', '.'],
    // Max 72 chars for subject line
    'header-max-length': [2, 'always', 72],
    // Body lines max 100 chars
    'body-max-line-length': [2, 'always', 100],
  },
};
