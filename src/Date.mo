import Order "mo:base/Order";
import Time "mo:base/Time";

import DateTypes "DateTypes";
import Components "mo:datetime/Components";
import DateTime "mo:datetime/DateTime";

module Date {

  type Year = DateTypes.Year;
  type Month = DateTypes.Month;
  type Day = DateTypes.Day;
  type DateParts = DateTypes.DateParts;

  // /**
  //  * The type of a date.
  //  */
  public type Date = Components.Components;

  /**
   * Check if the passed date is in the future.
   */
  public func isFutureDate(dispensation : Components.Components) : Bool {
    let now : Components.Components = Components.fromTime(Time.now());
    
    let res : Order.Order = Components.compare(now, dispensation);
    switch(res){
      case(#greater){
        return true;
      };
      case(_){
        return false;
      }
    }
  };

  /**
   * Check if the passed date is in the past.
   */
  public func isPastDate(date : Components.Components) : Bool {
    let now : Components.Components = Components.fromTime(Time.now());
    
    let res : Order.Order = Components.compare(now, date);
    switch(res){
      case(#greater){
        return true;
      };
      case(_){
        return false;
      }
    }
  };

  /**
   * Add years from now, return as Date Components.
   */
  public func addYearsFromNow(years: Nat) : Date {
    let now : Date = Components.fromTime(Time.now());
    let dt = DateTime.fromComponents(now);

    return dt.add(#years(years)).toComponents();
  };

  /**
   * time left from now, until passed target date in nanoseconds.
   */
  public func timeLeft(date : Components.Components) : Time.Time {
    let now = DateTime.fromComponents(Components.fromTime(Time.now()));
    let target = DateTime.fromComponents(date);
    return now.timeBetween(target);
  };

  /**
   * Show a date.
   */
  public func show(date : Components.Components) : Text {
    DateTypes.showDateParts(date);
  };

};