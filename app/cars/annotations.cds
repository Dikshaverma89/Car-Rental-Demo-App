using MainService as service from '../../srv/service';

// CARS – Main annotations
annotate service.Cars with @(
    UI.HeaderInfo              : {

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

    UI.LineItem                : [

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

    UI.SelectionFields         : [
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
    // CARS — UI.Facets
    // Maintenance facet hidden for non-admins
    UI.Facets                  : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneralInfo',
            Label : '{i18n>GeneralInformation}',
            Target: '@UI.FieldGroup#GeneralGroup',
        },
        {
            $Type        : 'UI.ReferenceFacet',
            Label        : '{i18n>RentalsInfo}',
            ID           : 'RentalsInfo',
            Target       : 'rentals/@UI.LineItem#RentalsInfo',
            //  hide on new draft — show only when record exists
            ![@UI.Hidden]: {$edmJson: {$Eq: [
                {$Path: 'IsActiveEntity'},
                false
            ]}}
        },
        {
            $Type        : 'UI.ReferenceFacet',
            Label        : '{i18n>MaintenanceInfo}',
            ID           : 'MaintenanceInfo',
            Target       : 'maintenance/@UI.LineItem#MaintenanceInfo',
            // hide for non-admins AND hide on new draft
            ![@UI.Hidden]: {$edmJson: {$Or: [
                {$Ne: [
                    {$Path: 'isAdmin'},
                    true
                ]},
                {$Eq: [
                    {$Path: 'IsActiveEntity'},
                    false
                ]}
            ]}}
        },
    ],

    UI.DataPoint #dailyPrice   : {
        $Type: 'UI.DataPointType',
        Value: dailyPrice,
        Title: '{i18n>DailyPrice}',
    },

    UI.DataPoint #status_code  : {
        $Type      : 'UI.DataPointType',
        Value      : status_code,
        Title      : '{i18n>Status}',
        Criticality: status.criticality,
    },

    UI.HeaderFacets            : [
        {
            $Type        : 'UI.ReferenceFacet',
            ID           : 'dailyPrice',
            Target       : '@UI.DataPoint#dailyPrice',
            //  CHANGED: was UI.Hidden: {$Path: 'IsActiveEntity'}
            // (IsActiveEntity=true in display mode)
            // Correct: hide when NOT active (i.e. in edit/draft mode)
            // ![@UI.Hidden] with $Ne means: hidden when IsActiveEntity != true
            ![@UI.Hidden]: {$edmJson: {$Ne: [
                {$Path: 'IsActiveEntity'},
                true
            ]}}
        },
        {
            $Type        : 'UI.ReferenceFacet',
            ID           : 'status_code',
            Target       : '@UI.DataPoint#status_code',
            // Same fix as above — was hiding in display mode, now hides in edit mode
            ![@UI.Hidden]: {$edmJson: {$Ne: [
                {$Path: 'IsActiveEntity'},
                true
            ]}}
        },
    ],

    UI.Identification          : [
        /*{
            $Type        : 'UI.DataFieldForAction',
            Action       : 'MainService.rent',
            Label        : '{i18n>Rent}',
            ![@UI.Hidden]: {$edmJson: {$Ne: [
                {$Path: 'IsActiveEntity'},
                true
            ]}}
        }, */
        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'MainService.setToMaintenance',
            Label        : '{i18n>SetToMaintenance}',
            //  Hide in edit mode OR when not admin
            ![@UI.Hidden]: {$edmJson: {$Or: [
                {$Ne: [
                    {$Path: 'IsActiveEntity'},
                    true
                ]},
                {$Ne: [
                    {$Path: 'isAdmin'},
                    true
                ]}
            ]}}
        },
    ]
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
]);


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
]);

// ADD these back — they block direct OData POST
annotate service.Rentals with @Capabilities.InsertRestrictions: {Insertable: false};
annotate service.Maintenance with @Capabilities.InsertRestrictions: {Insertable: false};

//@restrict → blocks at CAP/backend level
//Capabilities → blocks at OData metadata level
//UI.CreateHidden → hides at UI level

/// UI level — hides buttons visually
annotate service.Cars with @(
    UI.CreateHidden: {$edmJson: {$Not: {$Path: 'isAdmin'}}},
    UI.DeleteHidden: {$edmJson: {$Not: {$Path: 'isAdmin'}}},
    UI.UpdateHidden: {$edmJson: {$Not: {$Path: 'isAdmin'}}}
);

// OData level — signals non-insertable/updatable/deletable
annotate service.Cars with @(
    Capabilities.InsertRestrictions: {Insertable: {$edmJson: {$Path: 'isAdmin'}}},
    //Capabilities.UpdateRestrictions: { Updatable:  { $edmJson: { $Path: 'isAdmin' } } },
    Capabilities.DeleteRestrictions: {Deletable: {$edmJson: {$Path: 'isAdmin'}}},
    // Exclude new records from restriction
    Capabilities.UpdateRestrictions: {Updatable: {$edmJson: {$Or: [
        {$Path: 'isAdmin'},
        {$Eq: [
            {$Path: 'IsActiveEntity'},
            false
        ]}
    ]}}}
);

annotate service.Cars with {
    year @Common.Label: '{i18n>Year}'
};

/*
annotate MainService.Cars with @UI.SideEffects #AfterRent: {
    TriggerAction   : 'MainService.rent',
    TargetEntities  : [
        'MainService.Cars',
        'rentals'
    ],
    TargetProperties: ['IsActiveEntity']
};

annotate MainService.Cars with @UI.SideEffects #AfterMaintenance: {
    TriggerAction   : 'MainService.setToMaintenance',
    TargetEntities  : [
        'MainService.Cars',
        'maintenance'
    ],
    TargetProperties: ['IsActiveEntity']
};
*/

//SideEffects
annotate service.Cars with @(
    UI.SideEffects #AfterRent       : {
        TriggerActions  : ['MainService.Cars_rent'],
        TargetProperties: ['status_code'],
        TargetEntities  : [
            {$NavigationPropertyPath: 'rentals'},
            {$NavigationPropertyPath: 'status'}
        ]
    },

    UI.SideEffects #AfterMaintenance: {
        TriggerActions  : ['MainService.Cars_setToMaintenance'],
        TargetProperties: ['status_code'],
        TargetEntities  : [
            {$NavigationPropertyPath: 'maintenance'},
            {$NavigationPropertyPath: 'status'}
        ]
    },
);

// Brand value help
// Brand value help
annotate service.Cars with {
  brand @(
    Common.Label: 'Brand',
    Common.ValueList: {
      $Type         : 'Common.ValueListType',
      CollectionPath: 'CarBrands',
      Parameters    : [
        {
          // output name into brand field
          $Type            : 'Common.ValueListParameterOut',
          LocalDataProperty: brand,
          ValueListProperty: 'name',  // ← name not code
        },
        {
          // show code in dialog
          $Type            : 'Common.ValueListParameterDisplayOnly',
          ValueListProperty: 'code',
        },
        {
          // show name in dialog
          $Type            : 'Common.ValueListParameterDisplayOnly',
          ValueListProperty: 'name',
        },
      ],
    },
    Common.ValueListWithFixedValues: false,
  )
};
// Model value help — filters by brand + writes brand back
annotate service.Cars with {
  model @(
    Common.Label: 'Model',
    Common.ValueList: {
      $Type         : 'Common.ValueListType',
      CollectionPath: 'CarModels',
      Parameters    : [
        {
          $Type            : 'Common.ValueListParameterInOut',
          LocalDataProperty: brand,
          ValueListProperty: 'brandName',  // ← brandName ↔ brand
        },
        {
          $Type            : 'Common.ValueListParameterOut',
          LocalDataProperty: model,
          ValueListProperty: 'name',
        },
        {
          $Type            : 'Common.ValueListParameterDisplayOnly',
          ValueListProperty: 'code',
        },
        {
          // 🆕 show brandName in dialog
          $Type            : 'Common.ValueListParameterDisplayOnly',
          ValueListProperty: 'brandName',
        },
      ],
    },
    Common.ValueListWithFixedValues: false,
  )
};