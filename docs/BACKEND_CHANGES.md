# RealWorth API — changes required

Everything the Flutter app needs from `realestate_api` that could not be done in
the app repo. Written to be handed over as-is.

Each item states the problem, why it is not fixable client-side, the schema
change, the stored-procedure and service change, and what the app will do once
it lands. SQL is T-SQL against `PropertyListingsDB`.

---

## Before you start

**This was written against a stale checkout.** The reference copy was
`../realestate_api`, branch `feature/CombinedImprovements_jp`, commit `b037479`.
That copy has **no `/api/auth/register` endpoint at all**, yet registration works
in the deployed build — so the private upstream is ahead of it. The
`dylan-barker/realestate_api` remote returns *Repository not found* to the app
repo's collaborator, so none of this could be checked against current `master`.

Re-verify each item against current `master` before implementing. Where an item
says "today X", that describes commit `b037479`.

**Migration note.** The database is source-controlled as a SQL Server database
project (`Infrastructure/Database/PropertyListingsDB/`) with one file per object
and no migration runner. Each schema change below therefore needs both the
object file updated *and* an idempotent change script for existing databases.
The scripts here are written to be safely re-runnable.

---

## Summary

| #   | Item                              | Severity        | App state today                       |
| --- | --------------------------------- | --------------- | ------------------------------------- |
| 1   | Listings not scoped to an agent   | **Data leak**   | Shows every agent's listings          |
| 2   | No agent profile read/update      | Blocking        | Profile stored on device only         |
| 3   | Property type 4 mislabelled       | Cosmetic (DB)   | Already handled app-side              |
| 4   | No listing-level photos           | Blocking        | Photos captured, never uploaded       |
| 5   | List endpoint returns no detail   | Performance     | Works via one extra request per card  |
| 6   | Owner type not stored             | Minor           | Inferred from populated fields        |
| 7   | Condition rating widened to 1–6   | **No change**   | Works today — do not "fix"            |
| 8   | Register discards most fields     | Blocking        | Folded into item 2                    |
| 9   | Inconsistent error shapes         | Quality         | App has defensive parsing             |
| 10  | No write idempotency              | Reliability     | Duplicate rows possible on retry      |

---

## 1. Listings are not tied to an agent

**Severity: data exposure. Fix first.**

A newly registered agent signs in and sees listings created by other agents.
Reproduced on a fresh account: the home screen listed `LST-2026-00001` through
`LST-2026-00007`, none created by that account.

Not fixable in the app — it renders exactly what `GET /api/listings` returns.

Today `dbo.Listings` has no owner column, and `sp_Listings_GetAll` filters only
on status and date:

```sql
WHERE (@Status   IS NULL OR Status = @Status)
  AND (@DateFrom IS NULL OR CreatedAt >= @DateFrom)
  AND (@DateTo   IS NULL OR CreatedAt <= @DateTo)
```

`ListingsController` is `[Authorize(Roles = "Admin,Agent")]`, so the caller is
authenticated — the identity is simply never used.

### Schema

```sql
IF COL_LENGTH('dbo.Listings', 'UserId') IS NULL
BEGIN
    ALTER TABLE dbo.Listings ADD UserId INT NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Listings_Users')
BEGIN
    ALTER TABLE dbo.Listings WITH CHECK
        ADD CONSTRAINT FK_Listings_Users
        FOREIGN KEY (UserId) REFERENCES dbo.Users (Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Listings_UserId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Listings_UserId ON dbo.Listings (UserId);
END
GO
```

Nullable deliberately — existing rows have no owner.

**Decide explicitly what happens to the existing rows.** Either assign them:

```sql
UPDATE dbo.Listings SET UserId = @SomeUserId WHERE UserId IS NULL;
```

or accept that they become invisible to every agent. Do not leave this
undecided; `NULL` rows are unreachable once filtering is on. Once backfilled,
tighten with `ALTER COLUMN UserId INT NOT NULL`.

### Stored procedures

`sp_Listings_Create` — accept `@UserId INT` and persist it:

```sql
INSERT INTO Listings (ReferenceNumber, P24Ref, PropertyTypeId, Status, UserId, CreatedAt, UpdatedAt)
VALUES (@RefNum, @P24Ref, @PropertyTypeId, 'incomplete', @UserId, GETUTCDATE(), GETUTCDATE());
```

Note the reference-number generator takes `MAX(...) + 1` over all listings with
no locking. Two agents creating a listing in the same moment can collide on
`ReferenceNumber`. Consider a `SEQUENCE`, or a `UNIQUE` constraint on
`ReferenceNumber` plus a retry, while you are in this proc.

`sp_Listings_GetAll` — accept `@UserId INT` and add:

```sql
AND (@UserId IS NULL OR UserId = @UserId)
```

Pass `NULL` **only** for the `Admin` role, so admins keep a full view.

`sp_Listings_GetById`, `_Update`, `_Submit`, `_Delete` — accept `@UserId` and
include it in the `WHERE`, so an agent cannot reach another agent's listing by
guessing an id. Return zero rows on mismatch and let the controller map that to
`404` (not `403` — do not confirm the id exists).

### Child resources

`ListingRoomsController`, `ListingContactsController`,
`ListingParkingController`, `ListingOutdoorFeaturesController` and the address /
building-info / valuation / running-costs endpoints all take a listing id.
Each needs the same ownership check, or the parent guard is trivially bypassed
by going straight to `PUT /api/listings/{someoneElsesId}/address`.

Cheapest correct approach: one `ListingService.AssertOwnedAsync(listingId,
userId, ct)` called at the top of every listing-scoped operation.

### API

`ListingService` reads the user id from the JWT — `ClaimTypes.NameIdentifier`,
which `AuthService` already issues — never from the request body or a query
parameter.

### App impact

None. The app already calls these endpoints and will simply receive the
filtered set. Delete the seeded demo listings once this is live.

---

## 2. Agent profile cannot be read or updated

**Blocking Settings → My Profile.**

Registration collects full name, email, mobile, agency name, agency registration
number and FFC licence number. `dbo.Users` stores only `Id`, `Username`,
`PasswordHash`, `DisplayName`, `Role`, `IsActive`, `CreatedAt`. Everything else
is dropped on the floor, and there is no endpoint to read or write it.

The app currently persists these to `flutter_secure_storage`
(`lib/features/auth/providers/agent_profile_provider.dart`). That is a
stop-gap: it does not survive a reinstall, does not follow the agent to a second
device, and is invisible to the agency.

### Schema

```sql
IF COL_LENGTH('dbo.Users', 'Email') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD
        Email                    NVARCHAR(256) NULL,
        Mobile                   NVARCHAR(32)  NULL,
        AgencyName               NVARCHAR(200) NULL,
        AgencySlug               NVARCHAR(64)  NULL,
        AgencyRegistrationNumber NVARCHAR(64)  NULL,
        LicenceNumber            NVARCHAR(64)  NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Users_Email')
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_Users_Email
        ON dbo.Users (Email) WHERE Email IS NOT NULL;
END
GO
```

`AgencySlug` is the white-label key — see item 2b.

### Endpoints

```
GET /api/agents/me   -> 200 AgentProfileDto
PUT /api/agents/me   <- UpdateAgentProfileRequest -> 200 AgentProfileDto
```

```csharp
public record AgentProfileDto(
    int     Id,
    string  DisplayName,
    string? Email,
    string? Mobile,
    string? AgencyName,
    string? AgencySlug,
    string? AgencyRegistrationNumber,
    string? LicenceNumber,
    string  Role);

public record UpdateAgentProfileRequest(
    string  DisplayName,
    string  Email,
    string  Mobile,
    string? AgencyName,
    string? AgencySlug,
    string? AgencyRegistrationNumber,
    string? LicenceNumber);
```

Both resolve the user from the JWT. Neither accepts a user id in the route or
body.

`PUT` must **not** accept `Role`, `Username`, `IsActive` or `PasswordHash` —
otherwise an agent can promote themselves to `Admin`. A password change belongs
behind its own endpoint that verifies the current password.

Validate `Email` and return `400` with a field-keyed error (see item 9) so the
app can attach it to the right input.

### 2b. Agency slug vocabulary

The app white-labels itself per agency: picking one re-themes the whole app.
The slug is the contract between the two sides. Current values in
`lib/core/theme/agency.dart`:

```
realworth, remax, pam-golding, seeff, rawson, chas-everitt,
keller-williams, tyson, engel-volkers, harcourts, century-21,
jawitz, acutts
```

Store the slug as free text, not an enum or lookup FK — the app treats an
unknown slug as the house brand, so the two sides can drift without breaking.
An agent whose agency is not listed keeps a free-text `AgencyName` with a null
`AgencySlug`.

### App impact

`AgentProfile` becomes the DTO for both calls and the on-device copy becomes a
cache. Remove the "Stored on this device" note in `profile_screen.dart`.

---

## 3. Property type id 4 is still labelled "Vacant Land"

**Cosmetic, database-side only. Already handled in the app.**

Vacant land and plot described the same thing, so slot 4 was repurposed for
Commercial Property. The app shows "Commercial Property" and still sends id `4`,
so nothing was re-filed and there is no deploy-order dependency.

```sql
UPDATE dbo.PropertyType SET Description = 'Commercial Property' WHERE Id = 4;
```

**Check existing data first:**

```sql
SELECT Id, ReferenceNumber, PropertyTypeId FROM dbo.Listings WHERE PropertyTypeId = 4;
```

Anything there was captured as vacant land and may belong on `5` (Plot).

`PropertyTypeExtension.fromString` accepts both spellings, so the app is correct
either way.

Once this lands, consider pointing the app's picker at the live
`/api/property-types` lookup — the endpoint, `PropertyTypeDto` and
`LookupApiService.getPropertyTypes()` all exist already and are unused. That
removes this whole class of drift.

---

## 4. No listing-level photos

**Blocking the hero image on the home screen.**

Property Details now captures exterior photos with one nominated as the main
shot, and the listing cards are laid out around it. Only *room* photos can be
uploaded today (`POST /api/listings/{id}/rooms/{roomId}/photo`), so captured
paths stay on the device and cards render a placeholder.

### Schema

```sql
IF OBJECT_ID('dbo.ListingPhoto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ListingPhoto (
        Id        INT IDENTITY (1, 1) NOT NULL,
        ListingId INT           NOT NULL,
        Url       NVARCHAR(512) NOT NULL,
        IsPrimary BIT           NOT NULL CONSTRAINT DF_ListingPhoto_IsPrimary DEFAULT (0),
        SortOrder INT           NOT NULL CONSTRAINT DF_ListingPhoto_SortOrder DEFAULT (0),
        CreatedAt DATETIME      NOT NULL CONSTRAINT DF_ListingPhoto_CreatedAt DEFAULT (GETUTCDATE()),
        CONSTRAINT PK_ListingPhoto PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_ListingPhoto_Listing FOREIGN KEY (ListingId)
            REFERENCES dbo.Listings (Id) ON DELETE CASCADE
    );

    -- At most one primary photo per listing, enforced rather than assumed.
    CREATE UNIQUE NONCLUSTERED INDEX UX_ListingPhoto_Primary
        ON dbo.ListingPhoto (ListingId) WHERE IsPrimary = 1;
END
GO
```

The filtered unique index means "set primary" must clear the old primary and set
the new one **in one transaction**, or the second statement fails.

### Endpoints

```
GET    /api/listings/{id}/photos                  -> 200 ListingPhotoDto[]
POST   /api/listings/{id}/photos                  (multipart) -> 201 ListingPhotoDto
PUT    /api/listings/{id}/photos/{photoId}/primary -> 204
DELETE /api/listings/{id}/photos/{photoId}         -> 204
```

`Infrastructure/Services/R2ImageService.cs` already handles the upload path for
room photos — reuse it, with the same size and content-type limits.

The first photo uploaded to a listing should become primary automatically, so
the common case needs no second call.

Deleting a photo row should also delete the R2 object, or the bucket grows
forever. Room photo deletion likely has the same gap — worth checking.

### App impact

`PropertyState.exteriorPhotos` gains a save call in `savePropertyFeatures`, and
`_ListingCard` in `home_screen.dart` passes the primary URL into
`listingPhoto(...)` instead of the current `null`.

---

## 5. List endpoint returns nothing human-readable

**Performance, not correctness.**

`GET /api/listings` returns a reference number and status — nothing that tells
an agent *which house* a row is. The home screen needs address, owner and photo,
so it currently issues one extra `GET /api/listings/{id}` per card
(`PropertyRepository.getListingCardInfo`). Fine at the handful of listings one
agent owns; wasteful beyond that, and it is N+1 by construction.

Extend `sp_Listings_GetAll` and `ListingSummaryDto` with:

| Field              | Source                                          |
| ------------------ | ----------------------------------------------- |
| `StreetNumber`     | `ListingAddress`                                |
| `Street`           | `ListingAddress`                                |
| `Suburb`           | `ListingAddress`                                |
| `City`             | `ListingAddress`                                |
| `PrimaryOwnerName` | first `Contact` for the listing                 |
| `PrimaryPhotoUrl`  | `ListingPhoto WHERE IsPrimary = 1` (item 4)     |
| `RoomCount`        | `COUNT` over `ListingRoom`                      |

All are `LEFT JOIN`s — a listing with no address or owner must still come back.

### App impact

Delete `listingCardInfoProvider` (`home_screen.dart`) and
`PropertyRepository.getListingCardInfo`, and read the fields straight off
`ListingSummaryDto`.

---

## 6. Owner type is not stored

**Minor.**

Owner Details now asks whether an owner is a natural person or a business and
shows only that type's fields, instead of presenting ID number *and* company
registration number to everyone.

The app infers the type from which fields are populated. Correct in practice,
but it cannot represent a business whose name has not been typed yet, and it
guesses on data entered before this change.

```sql
IF COL_LENGTH('dbo.Contact', 'OwnerType') IS NULL
BEGIN
    ALTER TABLE dbo.Contact ADD OwnerType NVARCHAR(20) NULL;  -- 'Person' | 'Business'
END
GO
```

Add it to `ContactDto` and the contact upsert. `Contact.selectedOwnerType` in
the app is already the field to map onto.

---

## 7. Condition rating widened to six bands — no change needed

**Recorded so nobody "fixes" this later.**

The room condition scale went from four levels to six, stored as `1`–`6`:

| Level | Label           |
| ----- | --------------- |
| 1     | To be remodeled |
| 2     | To be renovated |
| 3     | Average         |
| 4     | Good            |
| 5     | Very good       |
| 6     | Excellent       |

`dbo.Condition.ConditionRating` is `DECIMAL(3,1)` with **no** `CHECK`
constraint, so `5` and `6` store correctly today and nothing is required.

**Do not add a range constraint without allowing 1–6.** Rows written under the
old 1–4 scale still read as their original band; `ConditionRating.fromStored`
clamps anything out of range.

Optionally seed `dbo.ConditionCategory` with these six labels so reporting can
join to a name rather than a bare number. The app does not read it.

---

## 8. Register endpoint discards most of what it is sent

The app posts to `POST /api/auth/register`:

```json
{
  "fullName": "...", "email": "...", "mobile": "...",
  "agencyName": "...", "agencyRegistrationNumber": "...",
  "licenceNumber": "...", "password": "..."
}
```

and receives `{ token, expiresAt, displayName, role, refreshToken }`.

Whatever the deployed implementation does, the columns for most of those fields
did not exist as of the reference commit — so they cannot have been persisted.
Once item 2's columns are in, store them all at registration, and add
`agencySlug` to the accepted payload (the app sends it once item 2b is agreed).

Registration should also reject a duplicate email with `409` and a field-keyed
error rather than a generic `500`.

---

## 9. Error response shapes are inconsistent

Not blocking — noted because the app carries defensive code for it.

`AuthNotifier._extractServerMessageForAuth`
(`lib/features/auth/providers/auth_provider.dart`) probes six different shapes
to find a usable message: `detail`, `Detail`, `title`, `Title`, `message`,
`Message`, `errors`, `Errors`, plus a bare string body. It also filters out HTML
bodies and stack traces, which means unhandled exceptions have reached the
client as HTML error pages at some point.

Settling on one shape — RFC 7807 `ProblemDetails`, which ASP.NET produces
natively — would let all that probing be deleted:

```json
{
  "type": "https://httpstatuses.io/400",
  "title": "Validation failed",
  "status": 400,
  "detail": "Email address is already registered.",
  "errors": { "email": ["Email address is already registered."] }
}
```

`ExceptionHandlingMiddleware` should guarantee that shape for every unhandled
path, and never emit an HTML page or a stack trace to a client.

---

## 10. Writes are not idempotent

Reliability, worth considering rather than doing now.

Agents work inside houses, frequently on poor signal. A request that times out
after the server committed it will be retried by the agent tapping Save again.
For the `PUT` upserts (address, building info, valuation, running costs) that is
harmless. For the `POST` collection endpoints — rooms, parking, contacts,
photos — it silently creates duplicates.

Options, cheapest first:

1. Accept a client-generated `Idempotency-Key` header on collection `POST`s and
   return the original response for a repeated key within, say, an hour.
2. Give rooms/contacts/parking a client-supplied stable id and make the
   endpoints upserts keyed on it, as the `PUT` endpoints already are.

The app already generates local ids for rooms, parking and contacts
(`custom-<millis>` and similar), so option 2 is a natural fit.

---

## Suggested order

1. **Item 1** — data exposure. Do this first and on its own.
2. **Item 3** — one `UPDATE`; ship it inside item 1's change script.
3. **Items 2 and 8** — same columns, do them together. Unblocks a screen that is
   currently device-local.
4. **Items 4 and 5** — together; item 5's `PrimaryPhotoUrl` depends on item 4.
5. **Item 6** — whenever `Contact` is next touched.
6. **Items 9 and 10** — quality and reliability, no deadline.

Item 7 needs nothing — it is there so the constraint does not get "tidied up".

---

## Contact points in the app

Should any of this need checking against the client:

| Concern            | File                                                            |
| ------------------ | --------------------------------------------------------------- |
| Endpoint paths     | `lib/core/network/api_endpoints.dart`                            |
| Listing reads      | `lib/features/property_overview/data/repositories/property_repository.dart` |
| Auth + JWT storage | `lib/features/auth/providers/auth_provider.dart`                 |
| Agent profile      | `lib/features/auth/data/models/agent_profile.dart`               |
| Agency slugs       | `lib/core/theme/agency.dart`                                     |
| Property type ids  | `lib/features/property_overview/data/models/enums/property_type.dart` |
| Condition levels   | `lib/features/property_overview/data/models/enums/condition_rating.dart` |
