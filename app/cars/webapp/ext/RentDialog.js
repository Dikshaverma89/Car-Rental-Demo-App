sap.ui.define([
    "sap/ui/core/Fragment",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageBox"
], function (Fragment, JSONModel, MessageBox) {
    "use strict"

    let _oDialog = null

    return {

        onRentPress: function (oBindingContext, aSelectedContexts, oEventParameters) {
            console.log("Rent pressed!")
            console.log("oBindingContext:", oBindingContext)

            const oModel = oBindingContext.getModel()
            const isAdmin = oBindingContext.getProperty("isAdmin")

            console.log("isAdmin:", isAdmin)

            const oDialogModel = new JSONModel({
                customer_ID: "",
                isAdmin: isAdmin
            })

            if (!_oDialog) {
                Fragment.load({
                    name: "cars.info.cars.ext.RentFragment",
                    controller: {
                        onRentConfirm: function () {
                            const oDateRange = sap.ui.getCore().byId("dateRange")
                            const startDate = oDateRange.getDateValue()
                            const endDate = oDateRange.getSecondDateValue()

                            if (!startDate || !endDate) {
                                MessageBox.error("Please select a date range")
                                return
                            }

                            // 🆕 validate customer ID for admin
                            const isAdmin     = oDialogModel.getProperty("/isAdmin")
                            const customer_ID = oDialogModel.getProperty("/customer_ID")

                            if (isAdmin && !customer_ID) {
                                MessageBox.error("Please enter a Customer ID")
                                return
                            }
                            
                            const fmt = d => d.toISOString().split("T")[0]

                            const oAction = oModel.bindContext(
                                "MainService.rent(...)",
                                oBindingContext
                            )

                            oAction.setParameter("startDate", fmt(startDate))
                            oAction.setParameter("endDate", fmt(endDate))
                            oAction.setParameter(
                                "customer_ID",
                                oDialogModel.getProperty("/isAdmin")
                                    ? oDialogModel.getProperty("/customer_ID")
                                    : ""
                            )

                            oAction.execute().then(() => {
                                _oDialog.close()
                                oBindingContext.refresh()
                                MessageBox.success("Car rented successfully!")
                            }).catch(err => {
                                MessageBox.error(err.message || "Rent failed")
                            })
                        },

                        onRentCancel: function () {
                            _oDialog.close()
                        }
                    }
                }).then(oDialog => {
                    _oDialog = oDialog
                    _oDialog.setModel(oDialogModel, "rentModel")
                    _oDialog.open()
                })
            } else {
                const oDateRange = sap.ui.getCore().byId("dateRange")
                if (oDateRange) {
                    oDateRange.setDateValue(null)
                    oDateRange.setSecondDateValue(null)
                }
                _oDialog.setModel(oDialogModel, "rentModel")
                _oDialog.open()
            }
        }
    }
})