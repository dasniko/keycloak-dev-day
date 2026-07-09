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

`assets/scss/` (theme colors, Bootstrap overrides) is the *source* for the compiled
`assets/css/theme.css`, but this repo has no Sass build step wired into Jekyll (the `.scss` files
carry no Jekyll front matter, so Jekyll won't process them) — `theme.css` is a separately compiled,
committed artifact. Editing `assets/scss/*.scss` alone has no effect on the served site; the compiled
CSS in `assets/css/theme.css` must be regenerated and committed separately (via the original DevConf
theme's own Sass toolchain) or edited directly for small tweaks.

## External integrations

- **Sessionize** — talk schedule widget (`_includes/schedule.html`).
- **Pretix** — ticket sales widget, URL from `site.pretix` in `_config.yml`.
- **Google Forms / Sendinblue** — feedback and newsletter forms, iframed via `layout: embedded`.
