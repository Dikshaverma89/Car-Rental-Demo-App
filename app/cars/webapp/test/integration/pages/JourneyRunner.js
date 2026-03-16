sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"cars/info/cars/test/integration/pages/CarsList",
	"cars/info/cars/test/integration/pages/CarsObjectPage"
], function (JourneyRunner, CarsList, CarsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('cars/info/cars') + '/test/flp.html#app-preview',
        pages: {
			onTheCarsList: CarsList,
			onTheCarsObjectPage: CarsObjectPage
        },
        async: true
    });

    return runner;
});

