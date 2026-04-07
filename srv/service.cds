using {my.rental as db} from '../db/schema';
using { S4VehicleCatalog as external } from './external/S4VehicleCatalog';
@requires: 'authenticated-user'
service MainService  {

  //Configuration Singleton
 
  @restrict: [{ grant: 'READ', to: ['user', 'admin'] }]
  entity Configuration {
    key ID    : String default 'singleton';  // ← dummy key
    userId  : String;
    isAdmin : Boolean;
  }
// 🆕 expose external entities through our service
  @readonly
  @restrict: [{ grant: 'READ', to: ['user', 'admin'] }]
  entity CarBrands as projection on external.VehicleBrands;

  @readonly
  @restrict: [{ grant: 'READ', to: ['user', 'admin'] }]
  entity CarModels as projection on external.VehicleModels {
    *,
    brandCode,           // keep original
  brandCode as brandName  // alias for filtering
  };

  // Cars – draft enabled for Fiori Elements create/edit flow
  // added @restrict
  // added virtual field : isAdmin
  @restrict: [
    {
      grant: 'READ',
      to   : [
        'user',
        'admin'
      ]
    },
    {
      grant: '*',
      to   : 'admin'
    }
  ]
  @odata.draft.enabled
  entity Cars               as
    projection on db.Cars {
      *,

      // Computed status_code using CDS CASE expression
      case
        when exists maintenance[startDate <= $now
             and endDate                  >= $now]
             then 'UM'
        when exists rentals[startDate <= $now
             and endDate              >= $now]
             then 'RE'
        else 'AV'
      end as status_code : String(5),

      status             : Association to AvailabilityStatus
                             on status.code = status_code,
      // virtual field — filled in service.js after READ
      // used by annotations to show/hide UI elements per role
      virtual isAdmin    : Boolean default false
    }

  @restrict: [
    {
      grant: 'READ',
      to   : 'admin'
    },
    {
      grant: 'READ',
      to   : 'user',
      where: 'ID = $user'
    }
  ]
  entity Customers          as projection on db.Customers;

  //@readonly
  @restrict: [
    {
      grant: 'READ',
      to   : 'admin'
    },
    {
      grant: 'READ',
      to   : 'user',
      where: 'customer_ID = $user'
    }
  ]
  entity Rentals            as
    projection on db.Rentals {
      *,
      customer.email as customerEmail : String
    };

  // @readonly
  // Maintenance for admin only
  @restrict: [{
    grant: '*',
    to   : 'admin'
  }]
  entity Maintenance        as projection on db.Maintenance;

  // CATEGORY + STATUS — read for all
  // added @restrict
  @restrict: [{ grant: 'READ', to: ['user' , 'admin']}]
  entity AvailabilityStatus as projection on db.AvailabilityStatus;

@restrict:[{ grant: 'READ' , to:[ 'user' , 'admin']}]
  entity Category           as projection on db.Category;

};

//Bound Action
//Added @restrict per action
extend MainService.Cars with actions {
// Both admin and user can rent
@restrict:[ {grant : 'INVOKE', to: ['user', 'admin']}]
  action rent(
              @Common.Label: 'Start Date'
              startDate: Date,

              @Common.Label: 'End Date'
              endDate: Date,

              @Common.Label: 'Customer ID'
              customer_ID: String(10)

  ) returns MainService.Rentals;

//Maintenance :  Only Admin
@restrict: [ { grant : 'INVOKE', to: 'admin'}]
  action setToMaintenance(
                          @Common.Label: 'Start Date'
                          startDate: Date,

                          @Common.Label: 'End Date'
                          endDate: Date,

                          @Common.Label: 'Description'
                          description: String(500),

                          @Common.Label: 'Cost'
                          cost: Decimal(10, 2)

  ) returns MainService.Maintenance;

}
