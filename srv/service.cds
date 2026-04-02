
using { my.rental as db } from '../db/schema';

service MainService {
  
  // Cars – draft enabled for Fiori Elements create/edit flow
   @odata.draft.enabled
  entity Cars as projection on db.Cars {
    *,

    // Computed status_code using CDS CASE expression 
    case
      when exists maintenance[ startDate <= $now and endDate >= $now ] then 'UM'
      when exists rentals[     startDate <= $now and endDate >= $now ] then 'RE'
      else 'AV'
    end as status_code : String(5),

    status : Association to AvailabilityStatus on status.code = status_code

  } 
  
  entity Customers as projection on db.Customers;

  @readonly
  entity Rentals as projection on db.Rentals {
    *,
    customer.email as customerEmail : String
  };

    @readonly
  entity Maintenance as projection on db.Maintenance;
  @readonly
  entity AvailabilityStatus as projection on db.AvailabilityStatus;

  @readonly
  entity Category as projection on db.Category;

};

//Bound Action
extend  MainService.Cars with actions {

  action rent(
    @Common.Label: 'Start Date'
    startDate   : Date,

    @Common.Label: 'End Date'
    endDate     : Date,

    @Common.Label: 'Customer ID'
    customer_ID : String(10)

  ) returns MainService.Rentals;

  action setToMaintenance(
    @Common.Label: 'Start Date'
    startDate   : Date,

    @Common.Label: 'End Date'
    endDate     : Date,

    @Common.Label: 'Description'
    description : String(500),

    @Common.Label: 'Cost'
    cost        : Decimal(10,2)

  ) returns MainService.Maintenance;

}