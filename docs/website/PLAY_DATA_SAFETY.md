# Google Play: Data safety answers

For Play Console → App content → Data safety. Based on what the app and API do as of
29 September 2026; revisit when analytics, crash reporting or new data sources are added.

## Overview questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS only) |
| Do you provide a way for users to request that their data is deleted? | **Yes**: in the app (Settings → Delete Account) and at `https://realworth.co.za/delete-account.html` |

On the account-deletion form, say that some data is kept: an agent's **listings** (property and
owner details, photos) stay with their agency as its business records of its mandates, and
**sales they logged** stay in the shared market data. Both are no longer linked to the agent, whose
name, contact details, registration numbers, password and profile are deleted.

## Data types

"Shared" means sent to a third party that is not a service provider acting for us. Public
look-ups (municipal data, OpenStreetMap address search) receive an address or location, not a
person, and hosting/storage providers are service providers, so none of these count as sharing.

| Data type | Collected | Shared | Required or optional | Purposes |
|---|---|---|---|---|
| **Personal info → Name** | Yes | No | Required | Account management, App functionality |
| **Personal info → Email address** | Yes | No | Required | Account management, App functionality |
| **Personal info → Phone number** | Yes | No | Optional | App functionality |
| **Personal info → Address** (property addresses) | Yes | No | Optional | App functionality |
| **Personal info → Other info** (ID numbers of owners, PPRA/FFC numbers) | Yes | No | Optional | App functionality |
| **Location → Precise location** | Yes | No | Optional (only on "Detect my address") | App functionality |
| **Photos and videos → Photos** | Yes | No | Optional | App functionality |
| **Files and docs** | Yes | No | Optional | App functionality |
| **Financial info → Other financial info** (property prices, valuations, purchase price) | Yes | No | Optional | App functionality |

Not collected: messages, contacts (the phone's address book), calendar, health, audio, web
browsing, app activity/analytics, crash logs, device IDs, advertising IDs.

## Other Play Console items

- **Privacy policy URL:** `https://realworth.co.za/privacy.html` (upload `docs/website/privacy.html`).
- **Account deletion URL:** `https://realworth.co.za/delete-account.html` (upload `docs/website/delete-account.html`).
- **Target audience:** 18 and over (property practitioners).
- **Ads:** No ads.
- **Location permission:** foreground only (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`); no background location.

## To fill in before publishing

In `privacy.html` and `delete-account.html`, replace the bracketed placeholders: the company's
registered name, registration number and address, the information officer, the hosting country,
and the backup and log retention periods. Make sure `privacy@realworth.co.za` exists and is read.
