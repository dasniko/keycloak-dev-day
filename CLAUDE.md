# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git commits

Unlike the global default, **do** add yourself (`Co-Authored-By: Claude ...`) as a co-author on commits
made with your support in this repository. This is an explicit per-repo override of the user's global
"never co-author" instruction.

## What this is

The static website for **KEYCLOAK DevDay**, a community conference, built with Jekyll. Content is
mostly plain HTML with Jekyll Liquid includes/data files, based on the "DevConf" Bootstrap 5 template
(3rdwavemedia).

## Development

Run via Docker Compose (no local Ruby/Jekyll install needed):

```
docker compose up
```

Serves at `http://localhost:4000` with `--watch --livereload` (livereload on port 35729).

Without Docker (requires Ruby + Bundler):

```
bundle install
bundle exec jekyll serve
```

There are no tests, linters, or build-check scripts in this repo — verification is visual (view the
served site).

Production build (what CI runs):

```
bundle exec jekyll build
```

Output goes to `_site/` (gitignored).

## Deployment

`.github/workflows/deploy.yml` runs on every push to `main`: builds with `bundle exec jekyll build`,
then `rsync`s `_site/` over SSH/sshpass to a Strato SFTP host. There is no staging environment — a
push to `main` deploys live. Be deliberate about pushing.

## Architecture: current edition vs. archived editions

This is the key structure to understand before editing anything:

- **`index.html`, `_includes/*.html`, `_data/*.yml`, `_config.yml`** together render the *current/
  upcoming* conference edition. This is the only part of the site that's actually templated — edit
  these for anything about the upcoming event.
- **`2024/index.html`, `2025/index.html`, `2026/index.html`** are frozen, fully self-contained static
  HTML snapshots of *past* editions — not built from `_includes` or Liquid data. They were produced by
  copying the fully-rendered `index.html` output at the end of each edition's cycle. Do not try to make
  them use includes/data; they're intentionally standalone archives.
- **When a new edition cycle starts**: the outgoing `index.html` (as rendered) gets copied into a new
  dated folder (e.g. `2027/index.html`), and `_config.yml`, `index.html`, `_data/sponsors.yml`, etc.
  get reset/updated for the next edition. The header nav's "Past editions" dropdown
  (`_includes/header.html`) is updated by hand to link to the new archive folder.

## Current-edition page assembly

`index.html` has Liquid front matter (`layout: none`) and pulls in, in order:
`header.html` → hero block (inline) → stats block (inline, loops `page.highlights`) → `about.html` →
`cfp.html` (gated by `site.showCfp`) → `speakers.html` (gated by `site.showSpeakers`) →
`schedule.html` (gated by `site.showSchedule`) → `tickets.html` → `venue.html` → `sponsors.html` →
`footer.html`.

Feature toggles live in `_config.yml`: `showTicketSale`, `showCfp`, `showSpeakers`, `showSchedule`.
Flip these to reveal/hide whole sections as the event lifecycle progresses (CfP open → speakers
announced → schedule published → tickets on sale).

Other standalone pages: `feedback.html`, `newsletter.html` use `layout: embedded`
(`_layouts/embedded.html`), which just iframes an external URL (`page.src` — Google Forms /
Sendinblue). `unkonf.html` renders the Open Space/Unconference grid from `_data/unkonf.yml`.

## Data-driven content

- `_data/sponsors.yml`: sponsor list consumed by `_includes/sponsors.html`, grouped by `type` (`gold`,
  `silver`, `sticker`). Inactive/past sponsors are kept as commented-out YAML entries rather than
  deleted — follow that convention when a sponsorship ends. Logo files referenced here live in
  `assets/images/logos/`.
- `_data/unkonf.yml`: Open Space schedule grid (time slots × rooms) rendered by `unkonf.html`. Empty
  `title` fields render an empty session card (used for slots not yet filled in).
- Talks/schedule for the current edition are not stored here — `_includes/schedule.html` embeds a
  Sessionize widget (`sessionize.com/api/v2/xsfibrpi/view/GridSmart`) rather than using local data.

## Styling

`assets/scss/theme.scss` (theme colors + `@import "bootstrap/scss/bootstrap.scss"` +
`@import "theme/styles.scss"`) is compiled by Jekyll's built-in Sass support (`jekyll-sass-converter`
→ libsass, already a transitive dependency of the `jekyll` gem — no extra tooling needed) on every
`jekyll build`/`jekyll serve`. The front matter on `theme.scss` (`permalink: /assets/css/theme.css`)
pins the compiled output to that path, matching what every page's `<link>` tag expects.
`assets/css/theme.css` is **generated, not committed** — don't hand-edit it or check it in; edit the
`.scss` source and rebuild.

Sass config lives in `_config.yml` under `sass:`. Two non-obvious settings:
- `sass_dir: assets/scss` — needed because the vendored Bootstrap tree lives outside the Jekyll
  default (`_sass`); without it, `@import "bootstrap/scss/bootstrap.scss"` fails to resolve.
- `sourcemap: never` — jekyll-sass-converter's sourcemap companion page copies the *entire* front
  matter (including our `permalink:`) onto the `.map` page, which makes it resolve to the exact same
  destination as `theme.css` and silently overwrite it with sourcemap JSON. Don't remove this setting
  without fixing that collision another way (e.g. dropping the custom `permalink:` and instead relying
  on Jekyll's default output path, which mirrors the source tree under `assets/scss/`, then updating
  every `<link>` tag to match).

Only the `theme.scss` entry point has front matter and gets compiled as a page; the vendored
`_*.scss` partials (Bootstrap source, `theme/_base.scss`, `theme/_home.scss`, etc.) are skipped by
Jekyll's site reader automatically (any file whose basename starts with `_` is excluded by default).
A few non-partial vendored files (`bootstrap-grid.scss`, `bootstrap-reboot.scss`,
`bootstrap-utilities.scss`, `theme/styles.scss`) have no front matter, so Jekyll just copies them
verbatim into `_site/assets/scss/` as inert, unreferenced files — harmless but not cleaned up.

Compressed (`style: compressed`) libsass output was verified byte-for-byte against the previously
hand-built `theme.css` it replaced; the only differences found were missing Autoprefixer vendor
prefixes and Bootstrap form/dark-mode-carousel rules this site's HTML never uses — see the
`scss-build-step` branch history for the full verification.

## External integrations

- **Sessionize** — talk schedule widget (`_includes/schedule.html`).
- **Pretix** — ticket sales widget, URL from `site.pretix` in `_config.yml`.
- **Google Forms / Sendinblue** — feedback and newsletter forms, iframed via `layout: embedded`.
