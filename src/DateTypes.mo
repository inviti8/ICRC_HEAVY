import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Components "mo:datetime/Components";

module DateTypes {

  /**
   * A type to represent a year.
   */
  public type Year = Int;

  /**
   * Show a year.
   */
  public func showYear(year : Year) : Text {
    Int.toText(year)
  };

  /**
   * A type to represent a month.
   */
  public type Month = Nat;

  /**
   * Show a month.
   */
  public func showMonth(month : Month) : Text {
    switch (month) {
      case (1) "January";
      case (2) "February";
      case (3) "March";
      case (4) "April";
      case (5) "May";
      case (6) "June";
      case (7) "July";
      case (8) "August";
      case (9) "September";
      case (10) "October";
      case (11) "November";
      case (12) "December";
      case (_) "Invalid";
    }
  };

  /**
   * Show a month using its abbreviation.
   */
  public func showMonthShort(month : Int) : Text {
    switch (month) {
      case (1) "Jan";
      case (2) "Feb";
      case (3) "Mar";
      case (4) "Apr";
      case (5) "May";
      case (6) "Jun";
      case (7) "Jul";
      case (8) "Aug";
      case (9) "Sep";
      case (10) "Oct";
      case (11) "Nov";
      case (12) "Dec";
      case (_) "Invalid";
    }
  };

  /**
   * A type to represent a day.
   */
  public type Day = Nat;

  /**
   * Show a day.
   */
  public func showDay(day : Day) : Text {
    Nat.toText(day)
  };

  /**
   * A type to represent a day of the week.
   */
  public type DayOfWeek = Components.DayOfWeek;

  /**
   * Show a day of the week.
   */
  public func showDayOfWeek(wday : DayOfWeek) : Text {
    switch (wday) {
      case (#sunday) "Sunday";
      case (#monday) "Monday";
      case (#tuesday) "Tuesday";
      case (#wednesday) "Wednesday";
      case (#thursday) "Thursday";
      case (#friday) "Friday";
      case (#saturday) "Saturday";
    }
  };

  /**
   * Show a day of the week using its abbreviation.
   */
  public func showDayOfWeekShort(wday : DayOfWeek) : Text {
    switch (wday) {
      case (#sunday) "Sun";
      case (#monday) "Mon";
      case (#tuesday) "Tue";
      case (#wednesday) "Wed";
      case (#thursday) "Thu";
      case (#friday) "Fri";
      case (#saturday) "Sat";
    }
  };

  /**
   * A type to represent a hour.
   */
  public type Hour = Nat;

  /**
   * Show a hour.
   */
  public func showHour(hour : Hour) : Text {
    Nat.toText(hour)
  };

  /**
   * A type to represent a minute.
   */
  public type Minute = Nat;

  /**
   * Show a minute.
   */
  public func showMinute(min : Minute) : Text {
    Nat.toText(min);
  };

  /**
   * A type to represent a second.
   */
  public type Second = Nat;

  /**
   * Show a second.
   */
  public func showSecond(sec : Second) : Text {
    Nat.toText(sec);
  };

  /**
   * A type to represent a nanosecond.
   */
  public type Nanos = Nat;

  /**
   * Show a nanosecond.
   */
  public func showNanos(nanos : Nanos) : Text {
    Nat.toText(nanos)
  };

  /**
   * A type to represent the parts of a date.
   */
  public type DateParts = {
    year : Year;
    month : Month;
    day : Day;
    wday : DayOfWeek;
  };

  /**
   * Show the parts of a date.
   */
  public func showDateParts(parts : Components.Components) : Text {
    var accum = "";
    let wday : Components.DayOfWeek = Components.dayOfWeek(parts);
    accum #= showDayOfWeekShort(wday);
    accum #= " ";
    accum #= showMonthShort(parts.month);
    accum #= " ";
    accum #= showWithPad(2, showDay(parts.day));
    accum #= " ";
    accum #= showWithPad(4, showYear(parts.year));
    accum
  };

  /**
   * A type to represent the parts of a date and time.
   */
  public type DateTimeParts = {
    year : Year;
    month : Month;
    day : Day;
    wday : DayOfWeek;
    hour : Hour;
    min : Minute;
    sec : Float;
  };

  /**
   * Apply a zero pad prefix up to the given length.
   */
  private func showWithPad(n : Nat, text : Text) : Text {
    var accum = text;
    var i = accum.size();
    while (i < n) {
      accum := "0" # accum;
      i += 1;
    };
    accum
  };
};