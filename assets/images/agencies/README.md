# Agency logos

One file per agency, named `<slug>.png`, where `<slug>` matches the `slug`
field in `lib/core/theme/agency.dart`.

| Agency                                    | File                            | Supplied |
| ----------------------------------------- | ------------------------------- | -------- |
| RealWorth (house brand)                   | `realworth.png`                 | —        |
| Acutts Real Estate                        | `acutts.png`                    | —        |
| Century 21                                | `century-21.png`                | yes      |
| Chas Everitt                              | `chas-everitt.png`              | yes      |
| Engel & Völkers                           | `engel-volkers.png`             | yes      |
| Harcourts                                 | `harcourts.png`                 | yes      |
| Jawitz Properties                         | `jawitz.png`                    | yes      |
| Just Property                             | `just-property.png`             | yes      |
| Keller Williams                           | `keller-williams.png`           | yes      |
| Leapfrog Property Group                   | `leapfrog.png`                  | yes      |
| Lew Geffen Sotheby's International Realty | `lew-geffen.png`                | yes      |
| Meridian Realty                           | `meridian.png`                  | yes      |
| Pam Golding Properties                    | `pam-golding.png`               | yes      |
| Property.CoZa                             | `property-coza.png`             | yes      |
| Quay 1 International Realty               | `quay-1.png`                    | yes      |
| Rawson Property Group                     | `rawson.png`                    | yes      |
| Realtors International                    | `realtors-international.png`    | yes      |
| RE/MAX                                    | `remax.png`                     | yes      |
| Seeff Property Group                      | `seeff.png`                     | yes      |
| Sotheby's International Realty            | `sothebys.png`                  | yes      |
| Tyson Properties                          | `tyson.png`                     | yes      |

RealWorth and Acutts have no file and render as monogram tiles.

## Requirements

- **Square.** `AgencyLogo` draws into a square box with `BoxFit.cover`, so a
  wide logo is centre-cropped and loses its ends. Pad to square before adding.
- At least 256×256. The existing files are up to 512×512.
- Transparent or brand-coloured background, both work.

## Adding an agency

1. Add an `Agency` entry to `lib/core/theme/agency.dart` with its brand colours.
   Sample them from the logo rather than guessing — several of the originals
   here were wrong until they were measured (Tyson read as maroon when it is
   dark teal; Rawson as blue when its identity is yellow).
2. Set `onPrimary` to a dark ink for any pale brand. A test asserts every entry
   clears WCAG AA contrast over its own primary, so a bad pair fails the suite.
3. Drop in `<slug>.png`. It is picked up automatically — no code change, and no
   entry needed in `pubspec.yaml`, which globs this folder.

## Licensing

These are third-party trademarks, included here because the brand owner
supplied them for this white-label build. Only add artwork you have the right
to distribute.
