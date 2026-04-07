/* checksum : 8e1a291a5b95237c469a63995fd2f740 */
@cds.external : true
service S4VehicleCatalog {
  @cds.external : true
  @cds.persistence.skip : true
  entity VehicleBrands {
    key code : String(20) not null;
    name : String(100);
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity VehicleModels {
    key code : String(20) not null;
    name : String(100);
    brandCode : String(20);
  };
};

