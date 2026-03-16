sap.ui.define(['sap/fe/test/ObjectPage'], function(ObjectPage) {
    'use strict';

    var CustomPageDefinitions = {
        actions: {},
        assertions: {}
    };

    return new ObjectPage(
        {
            appId: 'cars.info.cars',
            componentId: 'CarsObjectPage',
            contextPath: '/Cars'
        },
        CustomPageDefinitions
    );
});