namespace my.rental;

// Reusable aspect for start & end dates 
aspect HasPeriod {
  startDate : Date @mandatory   @title:'Start Date';
  endDate   : Date  @mandatory  @title:'End Date';
}
