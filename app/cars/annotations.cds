using MainService as service from '../../srv/service';
annotate service.Cars with @(
    UI.FieldGroup #GeneratedGroup : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : '{i18n>LicensePlate}',
                Value : licensePlate,
            },
            {
                $Type : 'UI.DataField',
                Label : '{i18n>Brand}',
                Value : brand,
            },
            {
                $Type : 'UI.DataField',
                Label : '{i18n>Model}',
                Value : model,
            },
            {
                $Type : 'UI.DataField',
                Label : '{i18n>Year}',
                Value : year,
            },
            {
                $Type : 'UI.DataField',
                Label : '{i18n>DailyPrice}',
                Value : dailyPrice,
            },
            {
                $Type : 'UI.DataField',
                Label : '{i18n>CategoryCode}',
                Value : category_code,
            },
        ],
    },
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : '{i18n>GeneralInformation}',
            Target : '@UI.FieldGroup#GeneratedGroup',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>RentalsInfo}',
            ID : 'RentalsInfo',
            Target : 'rentals/@UI.LineItem#RentalsInfo',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>MaintenanceInfo}',
            ID : 'MaintenanceInfo',
            Target : 'maintenance/@UI.LineItem#MaintenanceInfo',
        },
    ],
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : '{i18n>LicensePlate}',
            Value : licensePlate,
        },
        {
            $Type : 'UI.DataField',
            Label : '{i18n>Brand}',
            Value : brand,
        },
        {
            $Type : 'UI.DataField',
            Value : status_code,
            Label : 'Status',
            Criticality : status.criticality,
            CriticalityRepresentation : #WithIcon,
        },
        {
            $Type : 'UI.DataField',
            Label : '{i18n>DailyPrice}',
            Value : dailyPrice,
        },
        {
            $Type : 'UI.DataField',
            Label : '{i18n>Model}',
            Value : model,
        },
        {
            $Type : 'UI.DataField',
            Label : '{i18n>Year}',
            Value : year,
        },
    ],
    UI.HeaderInfo : {
        Title : {
            $Type : 'UI.DataField',
            Value : model,
        },
        TypeName : '',
        TypeNamePlural : '',
        Description : {
            $Type : 'UI.DataField',
            Value : brand,
        },
    },
    UI.DataPoint #dailyPrice : {
        $Type : 'UI.DataPointType',
        Value : dailyPrice,
        Title : '{i18n>DailyPrice}',
    },
    UI.HeaderFacets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'dailyPrice',
            Target : '@UI.DataPoint#dailyPrice',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'status_code',
            Target : '@UI.DataPoint#status_code',
        },
    ],
    UI.Identification : [
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'MainService.EntityContainer/rent',
            Label : '{i18n>Rent}',
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action : 'MainService.EntityContainer/setToMaintenance',
            Label : '{i18n>SetToMaintenance}',
        },
    ],
    UI.DataPoint #status_code : {
        $Type : 'UI.DataPointType',
        Value : status_code,
        Title : '{i18n>StatusCode}',
        Criticality : year,
    },
    UI.SelectionFields : [
        category_code,
        year,
        status_code,
    ],
);

annotate service.Cars with {
    category @(
        Common.ValueList : {
            $Type : 'Common.ValueListType',
            CollectionPath : 'Categories',
            Parameters : [
                {
                    $Type : 'Common.ValueListParameterInOut',
                    LocalDataProperty : category_code,
                    ValueListProperty : 'code',
                },
                {
                    $Type : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'name',
                },
            ],
        },
        Common.Label : '{i18n>Category}',
    )
};

annotate service.Rentals with @(
    UI.LineItem #RentalsInfo : [
        {
            $Type : 'UI.DataField',
            Value : car.rentals.startDate,
            Label : '{i18n>StartDate}',
        },
        {
            $Type : 'UI.DataField',
            Value : car.rentals.endDate,
            Label : '{i18n>EndDate}',
        },
        {
            $Type : 'UI.DataField',
            Value : car.rentals.totalPrice,
            Label : '{i18n>TotalPrice}',
        },
        {
            $Type : 'UI.DataField',
            Value : car.rentals.customer_ID,
            Label : '{i18n>CustomerId}',
        },
    ]
);

annotate service.Maintenance with @(
    UI.LineItem #MaintenanceInfo : [
        {
            $Type : 'UI.DataField',
            Value : car.maintenance.endDate,
            Label : '{i18n>EndDate}',
        },
        {
            $Type : 'UI.DataField',
            Value : car.maintenance.startDate,
            Label : '{i18n>StartDate}',
        },
        {
            $Type : 'UI.DataField',
            Value : car.maintenance.description,
            Label : '{i18n>Description}',
        },
        {
            $Type : 'UI.DataField',
            Value : car.maintenance.cost,
            Label : '{i18n>Cost}',
        },
    ]
);

annotate service.Cars with {
    year @Common.Label : '{i18n>Year}'
};

annotate service.Cars with {
        
status_code @(
    // tell FE that this list is small & fixed -> render as dropdown
    Common.ValueListWithFixedValues : true,
    

    // value help mapping
    Common.ValueList: {
      CollectionPath: 'AvailabilityStatus',
      Parameters: [
        {
          $Type: 'Common.ValueListParameterInOut',
          LocalDataProperty  : status_code,
          ValueListProperty  : 'code'
        },
        {
          $Type: 'Common.ValueListParameterDisplayOnly',
          ValueListProperty  : 'name'
        }
      ],
      UI.TextArrangement : #TextOnly
    },

  );


};

