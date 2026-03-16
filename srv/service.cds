using my.rental as db from '../db/schema';

service MainService {

@odata.draft.enabled
    entity Cars as projection on db.Cars {
        *,
        case
            when exists maintenance[
                startDate <= $now and endDate >= $now
            ]
                then 'UM'
            when exists rentals[
                startDate <= $now and endDate >= $now
            ]
                then 'RE'
            else 'AV'
        end as status_code : String(2),

        status : Association to db.AvailabilityStatus
                    on status.code = status_code
    };

    entity Customers   as projection on db.Customers;
    entity Rentals     as projection on db.Rentals;
    entity Maintenance as projection on db.Maintenance;
    entity AvailabilityStatus as projection on db.AvailabilityStatus;

    action rent(
        car_licensePlate : String,
        startDate : Date,
        endDate : Date,
        customer_ID : String
    ) returns Rentals;

    action setToMaintenance(
        car_licensePlate : String,
        startDate : Date,
        endDate : Date,
        description : String,
        cost : Decimal
    ) returns Maintenance;
}