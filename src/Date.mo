import Order "mo:base/Order";
import Time "mo:base/Time";

import DateTypes "DateTypes";
import Components "mo:datetime/Components";

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
   * Show a date.
   */
  public func show(date : Components.Components) : Text {
    DateTypes.showDateParts(date);
  };

};