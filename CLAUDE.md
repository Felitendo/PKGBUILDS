# CLAUDE.md

## Style

- Keep everything short: replies, explanations, comments, docs.
- Use simple English: short sentences, common words.
- Avoid em dashes (—). Do not just swap them for "-" either. Rewrite the sentence instead, for
  example with a comma, a colon, brackets or two sentences.

## Commits

- English only.
- Subject: `<package>: <what changed>`, the way CI writes it, for example
  `plezy-bin: update to 2.21.0-1` or `bottles-opener: new package`. Several packages at once:
  list them separated by commas.
- Subject as short as possible. Imperative, lowercase, no trailing period.
- Body only when something genuinely cannot be inferred from the diff.
- Never add `Co-Authored-By`, "Generated with" or any other AI attribution to commits or PR descriptions.

## Packages

- Read README.md first. The ground rule there decides what a package may do: this repository never
  hosts a binary of our own, and `-bin` is only for what upstream published.
- One directory per package with `PKGBUILD` and `pkg.sh`. `pkg.sh` tells CI how to find the newest
  version and how to refresh the checksums.
- Never bump `pkgver` or checksums by hand: CI does that every six hours.
