
using MainService as service from '../../srv/service';

// CARS – Main annotations
annotate service.Cars with @(
    UI.HeaderInfo: {
        
        Title         : {
            $Type: 'UI.DataField',
            Value: model,
        },
        TypeName      : 'Car',
        TypeNamePlural: 'Cars',
        Description   : {
            $Type: 'UI.DataField',
            Value: brand,
        },
    },

    UI.LineItem: [
        
        {
            $Type: 'UI.DataField',
            Label: '{i18n>LicensePlate}',
            Value: licensePlate,
        },
        {
            $Type: 'UI.DataField',
            Label: '{i18n>Brand}',
            Value: brand,
        },
        {
            $Type: 'UI.DataField',
            Label: '{i18n>Model}',
            Value: model,
        },
        {
            $Type: 'UI.DataField',
            Label: '{i18n>Year}',
            Value: year,
        },
        {
            $Type: 'UI.DataField',
            Label: '{i18n>DailyPrice}',
            Value: dailyPrice,
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : status_code,
            Label                    : '{i18n>Status}',
            Criticality              : status.criticality,
            CriticalityRepresentation: #WithIcon,
        },
        {
            $Type: 'UI.DataField',
            Label: '{i18n>Category}',
            Value: category_code,
        },
    ],

    UI.SelectionFields: [
        category_code,
        year,
        status_code,
    ],

    UI.FieldGroup #GeneralGroup: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Label: '{i18n>LicensePlate}',
                Value: licensePlate,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>Brand}',
                Value: brand,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>Model}',
                Value: model,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>Year}',
                Value: year,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>DailyPrice}',
                Value: dailyPrice,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>Category}',
                Value: category_code,
            },
        ],
    },

    UI.Facets: [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneralInfo',
            Label : '{i18n>GeneralInformation}',
            Target: '@UI.FieldGroup#GeneralGroup',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>RentalsInfo}',
            ID    : 'RentalsInfo',
            Target: 'rentals/@UI.LineItem#RentalsInfo',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>MaintenanceInfo}',
            ID    : 'MaintenanceInfo',
            Target: 'maintenance/@UI.LineItem#MaintenanceInfo',
        },
    ],

    UI.DataPoint #dailyPrice: {
        $Type: 'UI.DataPointType',
        Value: dailyPrice,
        Title: '{i18n>DailyPrice}',
    },

    UI.DataPoint #status_code: {
        $Type      : 'UI.DataPointType',
        Value      : status_code,
        Title      : '{i18n>Status}',
        Criticality: status.criticality,
    },

    UI.HeaderFacets: [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'dailyPrice',
            Target: '@UI.DataPoint#dailyPrice',
            //  CHANGED: was UI.Hidden: {$Path: 'IsActiveEntity'}
            // (IsActiveEntity=true in display mode)
            // Correct: hide when NOT active (i.e. in edit/draft mode)
            // ![@UI.Hidden] with $Ne means: hidden when IsActiveEntity != true
            ![@UI.Hidden]: { $edmJson: { $Ne: [ { $Path: 'IsActiveEntity' }, true ] } }
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'status_code',
            Target: '@UI.DataPoint#status_code',
            // Same fix as above — was hiding in display mode, now hides in edit mode
            ![@UI.Hidden]: { $edmJson: { $Ne: [ { $Path: 'IsActiveEntity' }, true ] } }
        },
    ],

    UI.Identification: [
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'MainService.rent',
            Label  : '{i18n>Rent}',
            ![@UI.Hidden]: { $edmJson: { $Ne: [ { $Path: 'IsActiveEntity' }, true ] } }
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'MainService.setToMaintenance',
            Label  : '{i18n>SetToMaintenance}',
            ![@UI.Hidden]: { $edmJson: { $Ne: [ { $Path: 'IsActiveEntity' }, true ] } }
        },
    ],

    // Side Effects – refresh status + tables after rent or setToMaintenance
  
/*
    UI.SideEffects #AfterMaintenance: {
        TriggerActions  : [ 'MainService.Cars_setToMaintenance' ],
        TargetProperties: [ 'status_code' ],
        TargetEntities  : [
            { $NavigationPropertyPath: 'maintenance' },
            { $NavigationPropertyPath: 'status'      }
        ]
    },
*/

);

// CARS – Value Help: category_code (dialog with table)
annotate service.Cars with {
    category_code @(
           Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Category',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterOut',
                    LocalDataProperty: category_code,
                    ValueListProperty: 'code',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'name',
                },
            ],
        },
       
        Common.ValueListWithFixedValues: false,
        Common.Label                   : '{i18n>Category}',
    )
};


// CARS – Value Help: status_code (dropdown)
annotate service.Cars with {
    status_code @(
      
        Common.ValueListWithFixedValues: true,
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'AvailabilityStatus',
            Parameters    : [
                {
                   
                    $Type            : 'Common.ValueListParameterOut',
                    LocalDataProperty: status_code,
                    ValueListProperty: 'code',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'name',
                },
            ],
            
        },
    )
};

// RENTALS – Object Page table columns
annotate service.Rentals with @(
    
    UI.LineItem #RentalsInfo: [
        {
            $Type: 'UI.DataField',
            Value: customer.email,
            Label: '{i18n>CustomerEmail}',
        },
        {
            $Type: 'UI.DataField',
            Value: startDate,
            Label: '{i18n>StartDate}',
        },
        {
            $Type: 'UI.DataField',
            Value: endDate,
            Label: '{i18n>EndDate}',
        },
        {
            $Type: 'UI.DataField',
            Value: totalPrice,
            Label: '{i18n>TotalPrice}',
        },
    ]
);


// MAINTENANCE – Object Page table columns

annotate service.Maintenance with @(
   
    UI.LineItem #MaintenanceInfo: [
        {
            $Type: 'UI.DataField',
            Value: startDate,
            Label: '{i18n>StartDate}',
        },
        {
            $Type: 'UI.DataField',
            Value: endDate,
            Label: '{i18n>EndDate}',
        },
        {
            $Type: 'UI.DataField',
            Value: description,
            Label: '{i18n>Description}',
        },
        {
            $Type: 'UI.DataField',
            Value: cost,
            Label: '{i18n>Cost}',
        },
    ]
);


// INSERT RESTRICTIONS – block direct OData POST on Rentals and Maintenance
annotate service.Rentals     with @Capabilities.InsertRestrictions: { Insertable: false };
annotate service.Maintenance with @Capabilities.InsertRestrictions: { Insertable: false };

annotate service.Cars with {
    year @Common.Label: '{i18n>Year}'
};

annotate MainService.Cars with @UI.SideEffects #AfterRent : {
    TriggerAction   : 'MainService.rent',
    TargetEntities  : [
        'MainService.Cars',
        'rentals'
    ],
    TargetProperties: [
        'IsActiveEntity'
    ]
};

annotate MainService.Cars with @UI.SideEffects #AfterMaintenance : {
    TriggerAction   : 'MainService.setToMaintenance',
    TargetEntities  : [
        'MainService.Cars',
        'maintenance'
    ],
    TargetProperties: [
        'IsActiveEntity'
    ]
};