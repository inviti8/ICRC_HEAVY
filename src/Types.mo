import ICPTypes "ICPTypes";
import CkETHTypes "CkETHTypes";
import CkBTCTypes "CkBTCTypes";

module {
  public type MintFromArgs = {
    coin: {#ICP; #ETH; #BTC;};
    source_subaccount: ?[Nat8];
    target: ?{ owner : Principal; subaccount : ?[Nat8] };
    amount : Nat;
  };
  public type MintFromICPArgs = {
    source_subaccount: ?[Nat8];
    target: ?ICPTypes.Account;
    amount : Nat;
  };
  public type MintFromCkETHArgs = {
    source_subaccount: ?[Nat8];
    target: ?CkETHTypes.Account;
    amount : Nat;
  };
  public type MintFromCkBTCArgs = {
    source_subaccount: ?[Nat8];
    target: ?CkBTCTypes.Account;
    amount : Nat;
  };
}