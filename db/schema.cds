namespace my.rental;

using { cuid } from '@sap/cds/common';
using { my.rental.HasPeriod } from './aspects';



/** Master data: Category (Sedan, SUV, ...) */
entity Category {
  key code : String(10);
  name     : String(100);
}

/** Master data: Availability status (Available, Rented, Under Maintenance) */
entity AvailabilityStatus {
  key code        : String(2);
  name            : String(40);
  criticality     : Integer; // 1: green (Available), 2: yellow (Rented), 3: red (UM)
}

/** Customers (use ID:String(10) as requested) */
entity Customers {
  key ID            : String(10);
  driverLicense     : String(40);  // unique (validated in service)
  email             : String(100); // unique (validated in service)
  firstName         : String(50);
  lastName          : String(50);
  phone             : String(30);
  address           : String(200);
}

/** Cars */
entity Cars {
  key licensePlate : String(20);
  brand            : String(60);
  model            : String(60);
  year             : Integer;
  dailyPrice       : Decimal(9,2);
  category         : Association to Category not null;

  // Compositions to enable nested tables on Object Page
  rentals     : Composition of many Rentals     on rentals.car = $self;
  maintenance : Composition of many Maintenance on maintenance.car = $self;
}

/** Rentals (use cuid + Period aspect) */
entity Rentals : cuid, HasPeriod {
  // ID comes from cuid
  totalPrice : Decimal(13,2)  @Core.Computed; // computed in service logic
  customer   : Association to Customers not null;
  car        : Association to Cars      not null;
}

/** Maintenance (use cuid + Period aspect) */
entity Maintenance : cuid, HasPeriod {
  description : String(200) not null;
  cost        : Decimal(13,2) not null;
  car         : Association to Cars not null;
}