namespace my.rental;

/** Reusable aspect for start & end dates */
aspect HasPeriod {
  startDate : Date    @title:'Start Date';
  endDate   : Date    @title:'End Date';
}
