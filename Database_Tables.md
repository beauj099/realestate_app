# Database Table Schema

---

## RoomTypes
- Id
- Description

## ConditionCategory
- Id
- Description

## Condition
- Id
- ListingRoomId
- ConditionRating
- Notes
- ConditionCategoryId

## ListingRoom
- Id
- ListingId
- Name
- RoomTypeId
- RoomTypeOther
- PhotoUrl
- CreatedAt
- UpdatedAt

## ListingRoomCustomFeature
- Id
- ListingRoomId
- Description

## Feature
- Id
- Category
- Description

## ListingRoomFeature
- Id
- ListingRoomId
- FeatureId

## ListingFeature
- Id
- ListingId
- FeatureId

## PropertyType
- Id
- Name
- SortOrder
- IsActive

## PropertyRunningCosts
- Id
- ListingId
- MonthlyLevy
- MonthlyRates
- Electricity
- Water

## ListingBuildingInfo
- Id
- ListingId
- ErfSize
- FloorArea
- ConstructionYear
- FacingId
- ZoningId

## Facing
- Id
- Description

## Zoning
- Id
- Description

## Listing
- Id
- ReferenceNumber
- P24Ref
- PropertyTypeId
- ListingValuationId
- ListDate
- Status
- CreatedAt
- UpdatedAt

## Contact
- Id
- FullName
- IdNumber
- CompanyName
- CompanyRegistrationNumber
- MobilePhone
- EmailAddress
- Role
- ListingId

## ListingAddress
- ListingAddressId
- ListingId
- ErfNumber
- EstateName
- StreetNumber
- UnitNumber
- Street
- Suburb
- City
- Province
- Country
- PostalCode
- Latitude
- Longitude

## ListingParking
- Id
- ListingId
- ParkingTypeId
- Quantity

## ParkingType
- Id
- Description

## ListingValuation
- Id
- OwnersNetPrice
- AgentValuation
- CommissionPercent