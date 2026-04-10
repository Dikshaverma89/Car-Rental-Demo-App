namespace my.rental;

using {cuid} from '@sap/cds/common';

// =============================================================================
// REUSABLE ASPECT: DateRange
// Reused by both Rentals and Maintenance to avoid repeating startDate/endDate
// =============================================================================
aspect DateRange {
  startDate : Date @mandatory;
  endDate   : Date @mandatory;
}

entity Category {
  key code : String(20);
      name : String(50);
}

// =============================================================================
// ENTITY: AvailabilityStatus  (value list — e.g. Available, Rented, Under Maintenance)
// criticality values used by Fiori for semantic colouring:
//   3 = green  (Available)
//   2 = yellow (Rented)
//   1 = red    (Under Maintenance)
// =============================================================================
entity AvailabilityStatus {
  key code        : String(5);
      name        : String(50);
      criticality : Integer;
}

// =============================================================================
// ENTITY: Cars
// Key       : licensePlate (natural business key)
// Relations : belongs to one Category
//             has many Rentals      (composition — Rentals owned by Car)
//             has many Maintenance  (composition — Maintenance owned by Car)
// =============================================================================
entity Cars {
  key licensePlate  : String(20);
      brand         : String(50)     @mandatory;
      model         : String(50)     @mandatory;
      year          : String(4)      @mandatory;
      dailyPrice    : Decimal(10, 2) @mandatory;

      category_code : String(20);
      // association uses category_code as FK
      category      : Association to Category
                        on category.code = category_code
                                     @mandatory;
      rentals       : Composition of many Rentals
                        on rentals.car = $self;
      // One Car has many Maintenance records
      maintenance   : Composition of many Maintenance
                        on maintenance.car = $self;
}

// =============================================================================
// ENTITY: Customers
// Key       : ID — String(10) business key (e.g. CUST001)
// Unique    : driverLicense, email
// Relations : has many Rentals (back-association for navigation)
// =============================================================================
entity Customers {
  key ID            : String(10);
      driverLicense : String(30)   @mandatory  @assert.unique;
      email         : String(100)  @mandatory  @assert.unique;
      firstName     : String(50)   @mandatory;
      lastName      : String(50)   @mandatory;
      phone         : String(20);
      address       : String(200);
      // One Customer has many Rentals
      rentals       : Association to many Rentals
                        on rentals.customer = $self;
}

// =============================================================================
// ENTITY: Rentals
// Key       : ID — auto-generated UUID via cuid aspect
// Aspect    : DateRange — adds startDate and endDate fields
// Virtual   : totalPrice — calculated in JS handler (days × dailyPrice)
//             not stored as a real column, computed on READ
// Relations : belongs to one Customer (required)
//             belongs to one Car      (required)
// =============================================================================
entity Rentals : cuid, DateRange {
  // Virtual field — not persisted in DB, calculated in service handler
  // @Core.Computed tells Fiori this field is read-only and auto-calculated
  totalPrice : Decimal(10, 2)           @Core.Computed: true;
  // Many Rentals belong to one Customer
  customer   : Association to Customers @mandatory;
  // Many Rentals belong to one Car
  car        : Association to Cars      @mandatory;
}

// =============================================================================
// ENTITY: Maintenance
// Key       : ID — auto-generated UUID via cuid aspect
// Aspect    : DateRange — adds startDate and endDate fields
// Relations : belongs to one Car (required)
// =============================================================================
entity Maintenance : cuid, DateRange {
  description : String(500)         @mandatory;
  cost        : Decimal(10, 2)      @mandatory;

  // Many Maintenance records belong to one Car
  car         : Association to Cars @mandatory;
}
