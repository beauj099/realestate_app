
## 4. API Endpoints

### 4.1 Reference / Lookup Data (GET only)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/property-types` | List property types (`SortOrder` asc, `IsActive`=true) |
| `GET` | `/api/room-types` | List room types |
| `GET` | `/api/features` | List features (client groups by `Category`) |
| `GET` | `/api/condition-categories` | List condition categories |
| `GET` | `/api/parking-types` | List parking types |
| `GET` | `/api/facing` | List facing directions |
| `GET` | `/api/zoning` | List zoning classifications |

### 4.2 Listing CRUD

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/api/listings` | Create listing in "draft" status, auto-generate `ReferenceNumber`, return full listing |
| `GET` | `/api/listings` | List all listings (optional filters: `status`, `dateFrom`, `dateTo`) |
| `GET` | `/api/listings/{id}` | Get single listing with all child entities nested (eager-loaded) |
| `PUT` | `/api/listings/{id}` | Update listing-level fields (`status`, `P24Ref`, `PropertyTypeId`) |
| `DELETE` | `/api/listings/{id}` | Delete listing and all related data |

### 4.3 Listing Sub-Resources (granular per-table upserts)

**Address**
- `PUT` `/api/listings/{id}/address` — upsert `ListingAddress`

**Building Info**
- `PUT` `/api/listings/{id}/building-info` — upsert `ListingBuildingInfo`

**Valuation & Running Costs**
- `PUT` `/api/listings/{id}/valuation` — upsert `ListingValuation`
- `PUT` `/api/listings/{id}/running-costs` — upsert `PropertyRunningCosts`

**Rooms**
- `GET` `/api/listings/{id}/rooms` — list rooms
- `POST` `/api/listings/{id}/rooms` — add room
- `PUT` `/api/listings/{id}/rooms/{roomId}` — update room
- `DELETE` `/api/listings/{id}/rooms/{roomId}` — delete room

**Room Condition**
- `PUT` `/api/listings/{id}/rooms/{roomId}/condition` — upsert `Condition`

**Room Features (junction)**
- `POST` `/api/listings/{id}/rooms/{roomId}/features` — link feature (`{featureId}` in body)
- `DELETE` `/api/listings/{id}/rooms/{roomId}/features/{featureId}` — unlink feature
- `POST` `/api/listings/{id}/rooms/{roomId}/custom-features` — add custom feature (`ListingRoomCustomFeature`)
- `DELETE` `/api/listings/{id}/rooms/{roomId}/custom-features/{id}` — remove custom feature

**Room Photo**
- `POST` `/api/listings/{id}/rooms/{roomId}/photo` — upload photo (multipart), return `PhotoUrl`

**Parking**
- `GET` `/api/listings/{id}/parking` — list parking entries
- `POST` `/api/listings/{id}/parking` — add parking entry
- `PUT` `/api/listings/{id}/parking/{parkingId}` — update quantity
- `DELETE` `/api/listings/{id}/parking/{parkingId}` — remove parking entry

**Contacts**
- `GET` `/api/listings/{id}/contacts` — list contacts
- `POST` `/api/listings/{id}/contacts` — add contact
- `PUT` `/api/listings/{id}/contacts/{contactId}` — update contact
- `DELETE` `/api/listings/{id}/contacts/{contactId}` — remove contact

### 4.4 Listing Lifecycle

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `PUT` | `/api/listings/{id}/submit` | Change status `"draft"`→`"submitted"`, set `ListDate` to now |

---
