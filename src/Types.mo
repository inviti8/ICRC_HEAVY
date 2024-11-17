module {
  public type MintFromArgs = {
    coin: {#ICP; #ETH; #BTC;};
    source_subaccount: ?[Nat8];
    target: ?{ owner : Principal; subaccount : ?[Nat8] };
    mintMark: ?Text;
    amount : Nat;
  };
  public type MintEphemeral = {
    target: ?{ owner : Principal; subaccount : ?[Nat8] };
    amount : Nat;
  };
  public type MarkType =  {
    mark : Text;
    logoUrl : Text;
  };
  public type DateType = {
    year : Nat;
    month : Nat;
    day : Nat;
    hour : Nat;
    minute : Nat;
    nanosecond : Nat;
  };
}