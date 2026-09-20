# Agency logos

Drop each white-label agency's logo here as `<slug>.png`, where `<slug>` matches
the `slug` field in `lib/core/theme/agency.dart`. Expected filenames:

| Agency                  | File                   |
| ----------------------- | ---------------------- |
| RealWorth (house brand) | `realworth.png`        |
| RE/MAX                  | `remax.png`            |
| Pam Golding Properties  | `pam-golding.png`      |
| Seeff Property Group    | `seeff.png`            |
| Rawson Property Group   | `rawson.png`           |
| Chas Everitt            | `chas-everitt.png`     |
| Keller Williams         | `keller-williams.png`  |
| Tyson Properties        | `tyson.png`            |
| Engel & Völkers         | `engel-volkers.png`    |
| Harcourts               | `harcourts.png`        |
| Century 21              | `century-21.png`       |
| Jawitz Properties       | `jawitz.png`           |
| Acutts Real Estate      | `acutts.png`           |

Guidelines:

- Square, at least 256×256, transparent background.
- A file is picked up automatically — no code change needed. Until one exists,
  `AgencyLogo` falls back to a monogram tile in the agency's colours, so a
  missing file never renders as a broken image.
- Only add artwork you have the right to distribute. These are third-party
  trademarks; none are committed to this repository.

Adding a new agency also needs an `Agency` entry in
`lib/core/theme/agency.dart` with its brand colours.
