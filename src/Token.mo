import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import CertTree "mo:cert/CertTree";

import ICRC1 "mo:icrc1-mo/ICRC1";
import ICRC2 "mo:icrc2-mo/ICRC2";
import ICRC3 "mo:icrc3-mo/";
import ICRC4 "mo:icrc4-mo/ICRC4";

import Types "Types";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Int32 "mo:base/Int32";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Map "mo:stable-hash-map/Map/Map";
import ICPTypes "ICPTypes";
import CkETHTypes "CkETHTypes";
import CkBTCTypes "CkBTCTypes";
import Date "Date";
import Components "mo:datetime/Components";
import Source "mo:uuid/async/SourceV4";
import UUID "mo:uuid/UUID";

shared ({ caller = _owner }) actor class Token  (args: ?{
    icrc1 : ?ICRC1.InitArgs;
    icrc2 : ?ICRC2.InitArgs;
    icrc3 : ICRC3.InitArgs; //already typed nullable
    icrc4 : ?ICRC4.InitArgs;
  }
) = this{

    let default_icrc1_args : ICRC1.InitArgs = {
      name = ?"Oroboros";
      symbol = ?"XRO";
      logo = ?"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMSIgaGVpZ2h0PSIxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9InJlZCIvPjwvc3ZnPg==";
      decimals = 16;
      fee = ?#Fixed(10000);
      minting_account = ?{
        owner = _owner;
        subaccount = null;
      };
      max_supply = null;
      min_burn_amount = ?10000;
      max_memo = ?64;
      advanced_settings = null;
      metadata = null;
      fee_collector = null;
      transaction_window = null;
      permitted_drift = null;
      max_accounts = ?100000000;
      settle_to_accounts = ?99999000;
    };

    let default_icrc2_args : ICRC2.InitArgs = {
      max_approvals_per_account = ?10000;
      max_allowance = ?#TotalSupply;
      fee = ?#ICRC1;
      advanced_settings = null;
      max_approvals = ?10000000;
      settle_to_approvals = ?9990000;
    };

    let default_icrc3_args : ICRC3.InitArgs = ?{
      maxActiveRecords = 3000;
      settleToRecords = 2000;
      maxRecordsInArchiveInstance = 100000000;
      maxArchivePages = 62500;
      archiveIndexType = #Stable;
      maxRecordsToArchive = 8000;
      archiveCycles = 20_000_000_000_000;
      archiveControllers = null; //??[put cycle ops prinicpal here];
      supportedBlocks = [
        {
          block_type = "1xfer"; 
          url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
        },
        {
          block_type = "2xfer"; 
          url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
        },
        {
          block_type = "2approve"; 
          url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
        },
        {
          block_type = "1mint"; 
          url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
        },
        {
          block_type = "1burn"; 
          url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
        }
      ];
    };

    let default_icrc4_args : ICRC4.InitArgs = {
      max_balances = ?200;
      max_transfers = ?200;
      fee = ?#ICRC1;
    };

    let icrc1_args : ICRC1.InitArgs = switch(args){
      case(null) default_icrc1_args;
      case(?args){
        switch(args.icrc1){
          case(null) default_icrc1_args;
          case(?val){
            {
              val with minting_account = switch(
                val.minting_account){
                  case(?val) ?val;
                  case(null) {?{
                    owner = _owner;
                    subaccount = null;
                  }};
                };
            };
          };
        };
      };
    };

    let icrc2_args : ICRC2.InitArgs = switch(args){
      case(null) default_icrc2_args;
      case(?args){
        switch(args.icrc2){
          case(null) default_icrc2_args;
          case(?val) val;
        };
      };
    };


    let icrc3_args : ICRC3.InitArgs = switch(args){
      case(null) default_icrc3_args;
      case(?args){
        switch(args.icrc3){
          case(null) default_icrc3_args;
          case(?val) ?val;
        };
      };
    };

    let icrc4_args : ICRC4.InitArgs = switch(args){
      case(null) default_icrc4_args;
      case(?args){
        switch(args.icrc4){
          case(null) default_icrc4_args;
          case(?val) val;
        };
      };
    };

    stable let icrc1_migration_state = ICRC1.init(ICRC1.initialState(), #v0_1_0(#id),?icrc1_args, _owner);
    stable let icrc2_migration_state = ICRC2.init(ICRC2.initialState(), #v0_1_0(#id),?icrc2_args, _owner);
    stable let icrc4_migration_state = ICRC4.init(ICRC4.initialState(), #v0_1_0(#id),?icrc4_args, _owner);
    stable let icrc3_migration_state = ICRC3.init(ICRC3.initialState(), #v0_1_0(#id), icrc3_args, _owner);
    stable let cert_store : CertTree.Store = CertTree.newStore();
    let ct = CertTree.Ops(cert_store);


    stable var owner = _owner;

    let #v0_1_0(#data(icrc1_state_current)) = icrc1_migration_state;

    private var _icrc1 : ?ICRC1.ICRC1 = null;

    private func get_icrc1_state() : ICRC1.CurrentState {
      return icrc1_state_current;
    };

    private func get_icrc1_environment() : ICRC1.Environment {
    {
      get_time = null;
      get_fee = null;
      add_ledger_transaction = ?icrc3().add_record;
      can_transfer = null; //set to a function to intercept and add validation logic for transfers
    };
  };

    func icrc1() : ICRC1.ICRC1 {
    switch(_icrc1){
      case(null){
        let initclass : ICRC1.ICRC1 = ICRC1.ICRC1(?icrc1_migration_state, Principal.fromActor(this), get_icrc1_environment());
        ignore initclass.register_supported_standards({
          name = "ICRC-3";
          url = "https://github.com/dfinity/ICRC/ICRCs/icrc-3/"
        });
        ignore initclass.register_supported_standards({
          name = "ICRC-10";
          url = "https://github.com/dfinity/ICRC/ICRCs/icrc-10/"
        });
        _icrc1 := ?initclass;
        initclass;
      };
      case(?val) val;
    };
  };

  let #v0_1_0(#data(icrc2_state_current)) = icrc2_migration_state;

  private var _icrc2 : ?ICRC2.ICRC2 = null;

  private func get_icrc2_state() : ICRC2.CurrentState {
    return icrc2_state_current;
  };

  private func get_icrc2_environment() : ICRC2.Environment {
    {
      icrc1 = icrc1();
      get_fee = null;
      can_approve = null; //set to a function to intercept and add validation logic for approvals
      can_transfer_from = null; //set to a function to intercept and add validation logic for transfer froms
    };
  };

  func icrc2() : ICRC2.ICRC2 {
    switch(_icrc2){
      case(null){
        let initclass : ICRC2.ICRC2 = ICRC2.ICRC2(?icrc2_migration_state, Principal.fromActor(this), get_icrc2_environment());
        _icrc2 := ?initclass;
        initclass;
      };
      case(?val) val;
    };
  };

  let #v0_1_0(#data(icrc4_state_current)) = icrc4_migration_state;

  private var _icrc4 : ?ICRC4.ICRC4 = null;

  private func get_icrc4_state() : ICRC4.CurrentState {
    return icrc4_state_current;
  };

  private func get_icrc4_environment() : ICRC4.Environment {
    {
      icrc1 = icrc1();
      get_fee = null;
      can_approve = null; //set to a function to intercept and add validation logic for approvals
      can_transfer_from = null; //set to a function to intercept and add validation logic for transfer froms
    };
  };

  func icrc4() : ICRC4.ICRC4 {
    switch(_icrc4){
      case(null){
        let initclass : ICRC4.ICRC4 = ICRC4.ICRC4(?icrc4_migration_state, Principal.fromActor(this), get_icrc4_environment());
        _icrc4 := ?initclass;
        initclass;
      };
      case(?val) val;
    };
  };

  let #v0_1_0(#data(icrc3_state_current)) = icrc3_migration_state;

  private var _icrc3 : ?ICRC3.ICRC3 = null;

  private func get_icrc3_state() : ICRC3.CurrentState {
    return icrc3_state_current;
  };

  func get_state() : ICRC3.CurrentState{
    return icrc3_state_current;
  };

  private func get_icrc3_environment() : ICRC3.Environment {
    ?{
      updated_certification = ?updated_certification;
      get_certificate_store = ?get_certificate_store;
    };
  };

  func ensure_block_types(icrc3Class: ICRC3.ICRC3) : () {
    let supportedBlocks = Buffer.fromIter<ICRC3.BlockType>(icrc3Class.supported_block_types().vals());

    let blockequal = func(a : {block_type: Text}, b : {block_type: Text}) : Bool {
      a.block_type == b.block_type;
    };

    if(Buffer.indexOf<ICRC3.BlockType>({block_type = "1xfer"; url="";}, supportedBlocks, blockequal) == null){
      supportedBlocks.add({
            block_type = "1xfer"; 
            url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
          });
    };

    if(Buffer.indexOf<ICRC3.BlockType>({block_type = "2xfer"; url="";}, supportedBlocks, blockequal) == null){
      supportedBlocks.add({
            block_type = "2xfer"; 
            url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
          });
    };

    if(Buffer.indexOf<ICRC3.BlockType>({block_type = "2approve";url="";}, supportedBlocks, blockequal) == null){
      supportedBlocks.add({
            block_type = "2approve"; 
            url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
          });
    };

    if(Buffer.indexOf<ICRC3.BlockType>({block_type = "1mint";url="";}, supportedBlocks, blockequal) == null){
      supportedBlocks.add({
            block_type = "1mint"; 
            url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
          });
    };

    if(Buffer.indexOf<ICRC3.BlockType>({block_type = "1burn";url="";}, supportedBlocks, blockequal) == null){
      supportedBlocks.add({
            block_type = "1burn"; 
            url="https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
          });
    };

    icrc3Class.update_supported_blocks(Buffer.toArray(supportedBlocks));
  };

  func icrc3() : ICRC3.ICRC3 {
    switch(_icrc3){
      case(null){
        let initclass : ICRC3.ICRC3 = ICRC3.ICRC3(?icrc3_migration_state, Principal.fromActor(this), get_icrc3_environment());
        _icrc3 := ?initclass;
        ensure_block_types(initclass);

        initclass;
      };
      case(?val) val;
    };
  };

  private func updated_certification(cert: Blob, lastIndex: Nat) : Bool{

    // D.print("updating the certification " # debug_show(CertifiedData.getCertificate(), ct.treeHash()));
    ct.setCertifiedData();
    // D.print("did the certification " # debug_show(CertifiedData.getCertificate()));
    return true;
  };

  private func get_certificate_store() : CertTree.Store {
    // D.print("returning cert store " # debug_show(cert_store));
    return cert_store;
  };

  /// Functions for the ICRC1 token standard
  public shared query func icrc1_name() : async Text {
      icrc1().name();
  };

  public shared query func icrc1_symbol() : async Text {
      icrc1().symbol();
  };

  public shared query func icrc1_decimals() : async Nat8 {
      icrc1().decimals();
  };

  public shared query func icrc1_fee() : async ICRC1.Balance {
      icrc1().fee();
  };

  public shared query func icrc1_metadata() : async [ICRC1.MetaDatum] {
      icrc1().metadata()
  };

  public shared query func icrc1_total_supply() : async ICRC1.Balance {
      icrc1().total_supply();
  };

  public shared query func icrc1_minting_account() : async ?ICRC1.Account {
      ?icrc1().minting_account();
  };

  public shared query func icrc1_balance_of(args : ICRC1.Account) : async ICRC1.Balance {
      icrc1().balance_of(args);
  };

  public shared query func icrc1_supported_standards() : async [ICRC1.SupportedStandard] {
      icrc1().supported_standards();
  };

  public shared query func icrc10_supported_standards() : async [ICRC1.SupportedStandard] {
      icrc1().supported_standards();
  };

  public shared ({ caller }) func icrc1_transfer(args : ICRC1.TransferArgs) : async ICRC1.TransferResult {
      switch(await* icrc1().transfer_tokens(caller, args, false, null)){
        case(#trappable(val)) val;
        case(#awaited(val)) val;
        case(#err(#trappable(err))) D.trap(err);
        case(#err(#awaited(err))) D.trap(err);
      };
  };

  // public shared ({ caller }) func mint(args : ICRC1.Mint) : async ICRC1.TransferResult {
  //     if(caller != owner){ D.trap("Unauthorized")};

  //     switch( await* icrc1().mint_tokens(caller, args)){
  //       case(#trappable(val)) val;
  //       case(#awaited(val)) val;
  //       case(#err(#trappable(err))) D.trap(err);
  //       case(#err(#awaited(err))) D.trap(err);
  //     };
  // };

  //ORO SPECIFIC CODE
  private func time64() : Nat64 {
    Nat64.fromNat(Int.abs(Time.now()));
  };

  stable var icpExchangeRate : Nat = 80_000_000_000_000_000;//8 oro for 1 ICP
  //stable var icpInflation : Nat = 888_8888_8888;//subtracted with each new mint
  stable var icpInflation : Nat = 98_8888_8888_8888;//TEST
  stable var ckEthExchangeRate : Nat = icpExchangeRate*8;//64 oro for 1 ckETH
  stable var ckEthInflation : Nat = icpInflation*8;//subtracted with each new mint
  stable var ckBtcExchangeRate : Nat = icpExchangeRate*80;//640 oro for 1 ckBTC
  stable var ckBtcInflation : Nat = icpInflation*80;//subtracted with each new mint
  stable var generatorCount : Nat = 0;

  var tick = 0;

  let ICP_LEDGER = "ryjl3-tyaaa-aaaaa-aaaba-cai";
  // let CK_ETH_LEDGER = "ss2fx-dyaaa-aaaar-qacoq-cai";
  let CK_ETH_LEDGER = "sh5u2-cqaaa-aaaar-qacna-cai";//testnet
  // let CK_BTC_LEDGER = "mxzaz-hqaaa-aaaar-qaada-cai";
  let CK_BTC_LEDGER = "mc6ru-gyaaa-aaaar-qaaaq-cai";//testnet

  let icpMinimum : Nat = 800_000_000;//e8s -> 8 icp token
  let icpMaximum : Nat = 80_000_000_000;//e8s -> 800 icp token
  let icpFee : Nat = 10_000;
  let ethMinimum : Nat = 10_000_000_000_000_000;// wei -> 0.01 eth
  let ethMaximum : Nat = 800_000_000_000_000_000;// wei -> 8 eth
  let ethFee : Nat = 2_000_000_000_000;//0.000002 ckETH
  let btcMinimum : Nat = 100_000;//sats -> 0.001 BTC
  let btcMaximum : Nat = 80_000_000; // sats -> 0.8 BTC
  let btcFee : Nat = 10;//0.0000001 ckBTC
  let oroFee : Nat = 10000; // 0.000000000001 oro 

  stable var icpTreasury : Nat = 0;
  stable var ethTreasury : Nat = 0;
  stable var btcTreasury : Nat = 0;
  
  let initiated : Components.Components = {
    year = 2024;
    month = 8;
    day = 8;
    hour = 0;
    minute = 0;
    nanosecond = 0;
  };
  //let maturity = 89999;//After this many mint calls, the price per oro in icp, eth, or btc becomes quite high
  let maturity = 89;//TEST
  //let dispensation = Date.create(#Year 2024, #August, #Day 8);//contract frozen until this date
  let dispensation : Components.Components = {
    year = 2025;
    month = 8;
    day = 8;
    hour = 0;
    minute = 0;
    nanosecond = 0;
  };//TEST

  stable var ephemeralMintCount : Nat = 0;
  stable var ephemeralReward : Nat = 888_0000_0000_0000_0000;
  stable var ephemeralMintedBalance : Nat = 0;
  stable var ephemeralRewardCycle : Nat = 0;
  stable var burnedBalance : Nat = 0;
  //stable var ephemeralMaxRewardCycles : Nat = 2522880000;//aproximately 80 years
  stable var ephemeralMaxRewardCycles : Nat = 80;//TEST
    //let ephemeralRewardInterval = 86400; // 1 day = 86400 sec
  let ephemeralRewardInterval = 88;//TEST
  let ephemeralAllocationSet = 10;

  let { nhash; phash; thash; } = Map;
  let generators = Map.new<Nat, Text>(nhash);
  let generator_principals = Map.new<Principal, Nat>(phash);
  let generator_accounts = Map.new<Nat, ?[Nat8]>(nhash);
  let generator_marks = Map.new<Principal, ?Text>(phash);
  let generator_coin_allocation = Map.new<Principal, Nat>(phash);
  let generator_allocation_type = Map.new<Principal, Text>(phash);
  let generator_holding_periods = Map.new<Principal, Text>(phash);
  let mark_generators = Map.new<Text, Text>(thash);
  let mark_logos = Map.new<Text, Text>(thash);
  let mark_allocation_type = Map.new<Text, Text>(thash);
  let mark_coin_allocation = Map.new<Text, Nat>(thash);
  

  let generations = Map.new<Text, Text>(thash);
  stable var generationJoinCost : Nat = 8;

  stable var generatorMintedBalance : Nat = 0;

  //Generators can withdraw their allocation after the holding period minus the network take.
  stable var generatorHoldingPeriod : Nat = 5;//5 years
  stable var ICPNetworkTakePercentage : Nat = 10;//10%
  stable var ETHNetworkTakePercentage : Nat = 3;//3%
  stable var BTCNetworkTakePercentage : Nat = 1;//1%
  stable var ICPNetworkTake : Nat = 0;
  stable var ETHNetworkTake : Nat = 0;
  stable var BTCNetworkTake : Nat = 0;

  //minters who create a mark have ability to create token drop events at burn cost
  let ephemeral_drop_events = Map.new<Text, Text>(thash);
  let ephemeral_drop_event_dates = Map.new<Text, Text>(thash);
  let ephemeral_drop_event_values = Map.new<Text, Nat>(thash);
  let ephemeral_drop_event_slots = Map.new<Text, Nat>(thash);
  let ephemeral_drop_event_urls = Map.new<Text, Text>(thash);
  let ephemeral_drops = Map.new<Text, Text>(thash);//Used for assignment
  let ephemeral_drop_accounts = Map.new<Text, ?[Nat8]>(thash);
  let ephemeral_drop_values = Map.new<Text, Nat>(thash);//Used for assignment
  let ephemeral_drop_slots = Map.new<Text, Nat>(thash);//Used for assignment
  //cost starts at 1/4 the value of the drop, so if you want to create a drop for 8 tokens you would need aprox. 10.75 tokens 
  stable var ephemeralDropCost : Nat = 25; 
  
  /**
   * This method mints ephemeral tokens for a given account.
   *
   * @param acct The account for which the tokens should be minted.
   * @return A `MintEphemeral` object representing the minted tokens, or `null` if there was an error.
   */
  private func ephemeralMint(acct : Nat) : async ?Types.MintEphemeral {

    return switch(Map.get<Nat, Text>(generators, nhash, acct)){//if generator exists, tokens are minted to them
        case(null){
          D.trap("Cannot Perform Ephemeral Mint.");
        };
        case(?gen){
          ?{
            target = switch(Map.get<Nat, ?[Nat8]>(generator_accounts, nhash, acct)){
              case(null){
                ?{
                  owner = Principal.fromText(gen);
                  subaccount = null;
                };
              };
              case(?val) {
                ?{
                  owner = Principal.fromText(gen);
                  subaccount = switch(val){
                    case(null) null;
                    case(?val) ?val;
                  };
                }
              };
            };
            amount = ephemeralReward+oroFee;
          };
        };
      };
  };

/**
 * This method is the heartbeat of the contract, responsible for periodically minting tokens and updating various state variables.
 */
  system func heartbeat() : async () {
    if (tick % ephemeralRewardInterval == 0) {
      Debug.print("generatorCount = " # debug_show(generatorCount));
      Debug.print("maturity = " # debug_show(maturity));
      if(generatorCount >= maturity){//at maturity ephemeral mint starts
        Debug.print("should do ephemeral mint!");

        if(ephemeralRewardCycle == 0){
          ephemeralRewardCycle := 1;
        };

        for (number in Iter.range(1, ephemeralAllocationSet)) {
          ignore mintEphemeralTokens(ephemeralMintCount);
          ephemeralMintCount := ephemeralMintCount + 1;
          if(ephemeralMintCount==maturity){
            ephemeralMintCount:=0;
            ephemeralRewardCycle := ephemeralRewardCycle + 1;
            if(ephemeralRewardCycle  < ephemeralMaxRewardCycles){
              ephemeralReward := (ephemeralReward / 8) * 7;//Reward decreased by 1/8
            };
          }; 
        };

      };
    };

    tick := tick + 1;
  };

  /**

  Mints ephemeral tokens for a given account.
  @param acct The account to mint tokens for. 
  
  */ 
  private func mintEphemeralTokens(acct : Nat) : async () {
    let args :  ?Types.MintEphemeral = await ephemeralMint(acct);
    var memo : Blob = Text.encodeUtf8("EPHEMERAL");
    Debug.print("EPHEMERAL MINT!");
    switch(args){
      case(null){
        Debug.print("Something went wrong with ephemeral mint args!");
        D.trap("Something went wrong with ephemeral mint args.");
      };
      case(?arg){
        let newtokens =  await* icrc1().mint_tokens(Principal.fromActor(this), {
          to = switch(arg.target){
              case(null){
                Debug.print("Mint target not found!");
                D.trap("Mint target not found.");
              };
              case(?val) {
                Debug.print("Mint Success!" # debug_show(acct));
                {
                  owner = val.owner;
                  subaccount = switch(val.subaccount){
                    case(null) null;
                    case(?val) ?Blob.fromArray(val);
                  };
                }
              };
            };
          amount = arg.amount;// The number of tokens to mint.
          created_at_time = ?time64();
          memo = ?(memo);
        });
      };
    };

  };

  /**
   * This method mints inflationary tokens based on the number of tokens already minted and the current exchange rate.
   *
   * @param args The arguments for the mint operation, including the coin type and amount to mint.
   * @param caller The principal that is calling this method.
   * @param memo A blob that contains additional information about the mint operation.
   */
  private func mintInflationaryTokens(args : Types.MintFromArgs, caller : Principal, memo : Blob ) : async ICRC1.TransferResult {
    
    // Calculate the exchange rate based on the number of tokens minted
    var exchangeRate : Nat = icpExchangeRate;
    if(generatorCount < maturity){//at maturity inflation stops
      switch (args.coin) {
        case (#ICP){
          exchangeRate -= icpInflation;
          icpExchangeRate -= icpInflation;
        };
        case (#ETH){
          exchangeRate := ckEthExchangeRate;
          exchangeRate -= ckEthInflation;
          ckEthExchangeRate -= ckEthInflation;
        };
        case (#BTC){
          exchangeRate := ckBtcExchangeRate;
          exchangeRate -= ckBtcInflation;
          ckBtcExchangeRate -= ckBtcInflation;
        };
      };
    };
    
    // Calculate the number of tokens to mint based on the exchange rate
    var mintingAmount : Nat = exchangeRate * (args.amount / 100_000_000);
    generatorMintedBalance := generatorMintedBalance + mintingAmount;
    generatorCount := generatorCount + 1;

    let newtokens = await* icrc1().mint_tokens(Principal.fromActor(this), {
        to = switch(args.target){
            case(null){
              {
                owner = caller;
                subaccount = null;
              }
            };
            case(?val) {
              {
                owner = val.owner;
                subaccount = switch(val.subaccount){
                  case(null) null;
                  case(?val) ?Blob.fromArray(val);
                };
              }
            };
          };               // The account receiving the newly minted tokens.
        amount = mintingAmount;           // The number of tokens to mint.
        created_at_time = ?time64();
        memo = ?(memo);
      });

      return switch(newtokens){
        case(#trappable(val)) val;
        case(#awaited(val)) val;
        case(#err(#trappable(err))) D.trap(err);
        case(#err(#awaited(err))) D.trap(err);
      };
  };

  /**
   * This method mints new tokens from the caller's account.
   * It first checks if the token is frozen, and if so, it raises an error.
   * Then it checks if the caller has already minted a token, and if so, it raises an error.
   * If both conditions are met, it mints the tokens and updates the relevant maps.
   *
   * @param args The arguments for the mint operation, including the coin type and amount to mint.
   */
  public shared ({ caller }) func mintFromToken(args : Types.MintFromArgs) : async ICRC1.TransferResult {

      // Check if the token is frozen
      switch (await isTokenFrozen()) {
        case (null) {
          D.trap("Something went wrong.");
        };
        case (?val) {
          if(val == true){
            D.trap("Token is frozen.");
          }
        };
      };

      // Check if the caller has already minted a token
      switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(caller) })) {
        case (null) {};
        case (?val) {
          D.trap("Only one mint per Principal is allowed.");
        };
      };

      var memo : Blob = Text.encodeUtf8("UNMARKED");
      var marked : Bool = false;
      var coin : Text = "ICP";

      // Add custom mark to coins
      switch (args.mintMark){
        case(null)  {};
        case(?val)  {
          switch (Map.get(generator_marks, phash, caller)){
            case (null){
              memo := Text.encodeUtf8(val);
              marked := true;
            };
            case(?mark) {
              D.trap("Coins are already minted with this mark, use another.");
            };
          };
        };
      };

      // Mint the tokens
      switch (args.coin) {
        case (#ICP){

          let ICPLedger : ICPTypes.Service = actor(ICP_LEDGER);

          // Check ICP balance of the callers dedicated account
          let balance = await ICPLedger.icrc1_balance_of(
            {
              owner = caller;
              subaccount = args.source_subaccount;
            }
          );

          if(balance < icpMinimum and args.amount < icpMinimum) {
            D.trap("Minimum mint amount is 1 ICP");
          };

          if(args.amount > icpMaximum) {
            D.trap("Maximum mint amount is 800 ICP");
          };
          
          let result = try{
            await ICPLedger.icrc2_transfer_from({
              to = {
                owner = Principal.fromActor(this);
                subaccount = null;
              };
              fee = null;
              spender_subaccount = null;
              from = {
                owner = caller;
                subaccount = args.source_subaccount;
              };
              memo = ?Blob.toArray(memo);
              created_at_time = ?time64();
              amount = args.amount-icpFee;
            });
          } catch(e){
            D.trap("cannot transfer from failed" # Error.message(e));
          };

          let block = switch(result){
            case(#Ok(block)){
              icpTreasury := icpTreasury + args.amount - icpFee;
              block;
            };
            case(#Err(err)){
                D.trap("cannot transfer from failed" # debug_show(err));
            };
          };

        };
        case (#ETH){

          let ETHLedger : CkETHTypes.Service = actor(CK_ETH_LEDGER);

          // Check ICP balance of the callers dedicated account
          let balance = await ETHLedger.icrc1_balance_of(
            {
              owner = caller;
              subaccount = args.source_subaccount;
            }
          );

          if(balance < ethMinimum and args.amount < ethMinimum) {
            D.trap("Minimum mint amount is 0.1 ETH");
          };

          if(args.amount > ethMaximum) {
            D.trap("Maximum mint amount is 8 ETH");
          };

          let result = try{
            await ETHLedger.icrc2_transfer_from({
              to = {
                owner = Principal.fromActor(this);
                subaccount = null;
              };
              fee = null;
              spender_subaccount = null;
              from = {
                owner = caller;
                subaccount = args.source_subaccount;
              };
              memo = ?Blob.toArray(memo);
              created_at_time = ?time64();
              amount = args.amount-ethFee;
            });
          } catch(e){
            D.trap("cannot transfer from failed" # Error.message(e));
          };

          let block = switch(result){
            case(#Ok(block)){
              ethTreasury := ethTreasury + args.amount - ethFee;
              coin:="ETH";
              block;
            };
            case(#Err(err)){
                D.trap("cannot transfer from failed" # debug_show(err));
            };
          };

        };
        case (#BTC){

          let BTCLedger : CkBTCTypes.Service = actor(CK_BTC_LEDGER);

          // Check ICP balance of the callers dedicated account
          let balance = await BTCLedger.icrc1_balance_of(
            {
              owner = caller;
              subaccount = args.source_subaccount;
            }
          );

          if(balance < btcMinimum and args.amount < btcMinimum) {
            D.trap("Minimum mint amount is 0.01 BTC");
          };

          if(args.amount > btcMaximum) {
            D.trap("Maximum mint amount is 0.8 BTC");
          };

          let result = try{
            await BTCLedger.icrc2_transfer_from({
              to = {
                owner = Principal.fromActor(this);
                subaccount = null;
              };
              fee = null;
              spender_subaccount = null;
              from = {
                owner = caller;
                subaccount = args.source_subaccount;
              };
              memo = ?Blob.toArray(memo);
              created_at_time = ?time64();
              amount = args.amount-btcFee;
            });
          } catch(e){
            D.trap("cannot transfer from failed" # Error.message(e));
          };

          let block = switch(result){
            case(#Ok(block)){
              btcTreasury := btcTreasury + args.amount - btcFee;
              coin:="BTC";
              block;
            };
            case(#Err(err)){
                D.trap("cannot transfer from failed" # debug_show(err));
            };
          };

        };
      };

      var result : ICRC1.TransferResult = await mintInflationaryTokens(args, caller, memo);

      let block = switch(result){
        case(#Ok(block)){
          var unlockDate : Components.Components = Date.addYearsFromNow(generatorHoldingPeriod);
          Map.set(generators, nhash, generatorCount, Principal.toText(caller));//Add minter to reconstruct
          Map.set(generator_principals, phash, caller, generatorCount);//Add minter to list for ephemeral minting
          Map.set(generator_accounts, nhash, generatorCount, args.source_subaccount);//Add minter to list for ephemeral minting
          Map.set(generator_coin_allocation, phash, caller, args.amount);//Add minter to list for ephemeral minting
          Map.set(generator_allocation_type, phash, caller, coin);//Add coin type to map
          Map.set(generator_holding_periods, phash, caller, _dateComponentsToText(unlockDate));//Add holding period to map
          switch(Text.decodeUtf8(memo)){
            case(null){};
            case(?mem){
              Map.set(mark_allocation_type, thash, mem, coin);
              Map.set(mark_coin_allocation, thash, mem, args.amount);
            };
          };
          if(marked){
            switch(Text.decodeUtf8(memo)){
              case(null){
                Map.set(generator_marks, phash, caller, Text.decodeUtf8(memo));//if coin is marked add memo to map
              };
              case(?mark){
                Map.set(generator_marks, phash, caller, Text.decodeUtf8(memo));//if coin is marked add memo to map
                Map.set(mark_generators, thash, mark, Principal.toText(caller));
              };
            };
          };

          switch (args.coin) {

            case (#ICP){
              ICPNetworkTake := Nat.mul(Nat.div(args.amount, 100), ICPNetworkTakePercentage);
            };
            case (#ETH){
              ETHNetworkTake := Nat.mul(Nat.div(args.amount, 100), ETHNetworkTakePercentage);
            };
            case (#BTC){
              BTCNetworkTake := Nat.mul(Nat.div(args.amount, 100), BTCNetworkTakePercentage);
            };
          };

          block;
        };
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      return result;
  };

/**
 * Withdraw Generator Allocated ICP tokens.
 *
 * @param {Principal} principal that is trying to withdraw.
 * @return {ICPTypes.Result_2}
 */
 public shared func withdrawICPAllocation(caller : Principal) : async ICPTypes.Result_2 {
    if(_holdingPeriodComplete(caller) == false){ D.trap("Unauthorized, holding period is not complete.")};
    switch(Map.get(generator_allocation_type, phash, caller)){
      case(null){
         D.trap("Unauthorized, no allocation found.");
       };
      case(?coin){
        if(coin == "ICP"){

          switch(Map.get(generator_coin_allocation, phash, caller)){
            case(null){

              D.trap("Unauthorized, no allocation found.");
              
            };
            case(?val){
              if(val==0){

                D.trap("Unauthorized, insuffiecient allocation.");

              }else{

                var networkTake : Nat = Nat.mul(Nat.div(val, 100), ICPNetworkTakePercentage);
                var alloc : Nat = val - networkTake;
                let result = await _withdrawICP (caller, alloc);

                let block = switch(result){

                  case(#Ok(block)) {
                    _updateGeneratorAllocation(caller, 0);
                    return result;
                  };
                  case(#Err(err)){
                    D.trap("Cannot withdraw allocation." # debug_show(err));
                  };
                };
                
              };
            };
          };

        }else{
          D.trap("Unauthorized, invalid allocation type.");
        };

      };
    };
    
  };

  private func _withdrawICP(caller : Principal, amount : Nat) : async ICPTypes.Result_2 {

      let ICPLedger : ICPTypes.Service = actor(ICP_LEDGER);
      var memo : Blob = Text.encodeUtf8("ICP-OUT");

      // check ICP balance of the canister
      let balance = await ICPLedger.icrc1_balance_of(
        {
          owner = Principal.fromActor(this);
          subaccount = null;
        }
      );

      if(balance < amount + icpFee){
        D.trap("Not enough Balance");
      };

      let result = try{
        await ICPLedger.icrc2_transfer_from({
            to = {
              owner = caller;
              subaccount = null;
            };
            fee = ?icpFee;
            spender_subaccount = null;
            from = {
              owner = Principal.fromActor(this);
              subaccount = null;
            };
            memo = ?Blob.toArray(memo);
            created_at_time = ?time64();
            amount = amount-icpFee;
          });
      } catch(e){
        D.trap("cannot transfer from failed" # Error.message(e));
      };

      let block = switch(result){
        case(#Ok(block)) {
          icpTreasury -= (amount + icpFee);
          block;
        };
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      result;
  };

  /**
   * Withdraw Generator Allocated ckETH tokens.
   *
   * @param {Principal} principal that is trying to withdraw.
   * @return {CkETHTypes.Result_2}
   */
  public shared func withdrawCkETHAllocation(caller : Principal) : async CkETHTypes.Result_2 {
    if(_holdingPeriodComplete(caller) == false){ D.trap("Unauthorized, holding period is not complete.")};
    switch(Map.get(generator_allocation_type, phash, caller)){
      case(null){
         D.trap("Unauthorized, no allocation found.");
       };
      case(?coin){
        if(coin == "ETH"){

          switch(Map.get(generator_coin_allocation, phash, caller)){
            case(null){

              D.trap("Unauthorized, no allocation found.");

            };
            case(?val){
              if(val==0){

                D.trap("Unauthorized, insuffiecient allocation.");

              }else{

                var networkTake : Nat = Nat.mul(Nat.div(val, 100), ETHNetworkTakePercentage);
                var alloc : Nat = val - networkTake;
                let result = await _withdrawCkETH (caller, alloc);

                let block = switch(result){

                  case(#Ok(block)) {
                    _updateGeneratorAllocation(caller, 0);
                    return result;
                  };
                  case(#Err(err)){
                    D.trap("Cannot withdraw allocation." # debug_show(err));
                  };
                };
                
              };
            };
          };

        }else{
          D.trap("Unauthorized, invalid allocation type.");
        };

      };
    };
    
  };

  private func _withdrawCkETH(caller : Principal, amount : Nat) : async CkETHTypes.Result_2 {

      let ETHLedger : CkETHTypes.Service = actor(CK_ETH_LEDGER);
      var memo : Blob = Text.encodeUtf8("ckETH-OUT");

      // check ckETH balance of the canister
      let balance = await ETHLedger.icrc1_balance_of(
        {
          owner = Principal.fromActor(this);
          subaccount = null;
        }
      );

      if(balance < amount + ethFee){
        D.trap("Not enough Balance");
      };

      let result = try{
        await ETHLedger.icrc2_transfer_from({
            to = {
              owner = caller;
              subaccount = null;
            };
            fee = ?ethFee;
            spender_subaccount = null;
            from = {
              owner = Principal.fromActor(this);
              subaccount = null;
            };
            memo = ?Blob.toArray(memo);
            created_at_time = ?time64();
            amount = amount-ethFee;
          });
      } catch(e){
        D.trap("cannot transfer from failed" # Error.message(e));
      };

      let block = switch(result){
        case(#Ok(block)) {
          ethTreasury -= (amount + ethFee);
          block;
        };
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      result;
  };

  /**
   * Withdraw ckBTC tokens.
   *
   * @param {Principal} principal that is trying to withdraw.
   * @return {CkBTCTypes.Result_2}
   */
  public shared func withdrawCkBTCAllocation(caller : Principal) : async CkBTCTypes.Result_2 {
    if(_holdingPeriodComplete(caller) == false){ D.trap("Unauthorized, holding period is not complete.")};
    switch(Map.get(generator_allocation_type, phash, caller)){
      case(null){
         D.trap("Unauthorized, no allocation found.");
       };
      case(?coin){
        if(coin == "BTC"){

          switch(Map.get(generator_coin_allocation, phash, caller)){
            case(null){

              D.trap("Unauthorized, no allocation found.");

            };
            case(?val){
              if(val==0){

                D.trap("Unauthorized, insuffiecient allocation.");

              }else{

                var networkTake : Nat = Nat.mul(Nat.div(val, 100), BTCNetworkTakePercentage);
                var alloc : Nat = val - networkTake;
                let result = await _withdrawCkBTC (caller, alloc);

                let block = switch(result){

                  case(#Ok(block)) {
                    _updateGeneratorAllocation(caller, 0);
                    return result;
                  };
                  case(#Err(err)){
                    D.trap("Cannot withdraw allocation." # debug_show(err));
                  };
                };
                
              };
            };
          };

        }else{
          D.trap("Unauthorized, invalid allocation type.");
        };

      };
    };
    
  };

  private func _withdrawCkBTC(caller : Principal, amount : Nat) : async CkBTCTypes.Result_2 {

      let BTCLedger : CkBTCTypes.Service = actor(CK_BTC_LEDGER);
      var memo : Blob = Text.encodeUtf8("ckBTC-OUT");

      // check ckBTC balance of the canister
      let balance = await BTCLedger.icrc1_balance_of(
        {
          owner = Principal.fromActor(this);
          subaccount = null;
        }
      );

      if(balance < amount + btcFee){
        D.trap("Not enough Balance");
      };

      let result = try{
        await BTCLedger.icrc2_transfer_from({
            to = {
              owner = caller;
              subaccount = null;
            };
            fee = ?btcFee;
            spender_subaccount = null;
            from = {
              owner = Principal.fromActor(this);
              subaccount = null;
            };
            memo = ?Blob.toArray(memo);
            created_at_time = ?time64();
            amount = amount-btcFee;
          });
      } catch(e){
        D.trap("cannot transfer from failed" # Error.message(e));
      };

      let block = switch(result){
        case(#Ok(block)){
          btcTreasury -= (amount + btcFee);
          block;
        };
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      result;
  };

  private func _updateGeneratorAllocation(caller : Principal, value : Nat) {
    Map.set(generator_coin_allocation, phash, caller, value);
      switch (Map.get(generator_marks, phash, caller)){
        case (null){};
        case(?mark) {
          switch(mark){
            case(null){};
            case(?m){
              Map.set(mark_coin_allocation, thash, m, value);
            };
          };
        };
    };
  };

  private func _burnTokens(caller : Principal, amount : Nat) : async ICRC2.TransferFromResponse {

      var memo : Blob = Text.encodeUtf8("ORO-BURN");

      // check balance
      let balance = await this.icrc1_balance_of(
        {
          owner = caller;
          subaccount = null;
        }
      );

      if(balance < amount + oroFee){
        D.trap("Not enough Balance");
      };

      let result = try{
        await this.icrc2_transfer_from({
            to = {
              owner = Principal.fromActor(this);
              subaccount = null;
            };
            fee = ?oroFee;
            spender_subaccount = null;
            from = {
              owner = caller;
              subaccount = null;
            };
            memo = ?memo;
            created_at_time = ?time64();
            amount = amount-oroFee;
          });
      } catch(e){
        D.trap("cannot transfer from failed" # Error.message(e));
      };

      let block = switch(result){
        case(#Ok(block)) {
          burnedBalance += (amount + oroFee);
          block;
        };
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      result;
  };

  public query func isTokenFrozen() : async ? Bool{
    return do ? {
        Date.isFutureDate(dispensation);
    };
  };

  public query func getGeneratorEpoch(args : ICRC1.Account) : async ?Nat{
    return Map.get(generator_principals, phash, args.owner);
  };

  public query func getGeneratorLogo(mark : Text) : async ?Text{
    return Map.get(mark_logos, thash, mark);
  };

  private func _ephemeralDropKey( acct : Text, mark : Text ) : Text{
    let delimit = mark # "|";
    return Text.concat(delimit, acct);
  };

  private func _isPngUrl(url : Text) : Bool {
    return (Text.startsWith(url, #text "https://" ) and Text.endsWith(url, #text ".png"))
  };

  private func _generationKey( acct : Text, moniker : Text ) : Text{
    let delimit = moniker # "|";
    return Text.concat(delimit, acct);
  };

  private func _dateType( acct : Text, mark : Text ) : ? Types.DateType{
    let key = _ephemeralDropKey(acct, mark);

    switch (Map.get(ephemeral_drops, thash, key)) {
      case (null) {
        return null;
      };
      case (?val) {
        return _textToDateType(val);
      };
    };

  };

  private func _holdingPeriodComplete(caller : Principal) : Bool {
    switch (Map.get(generator_holding_periods, phash, caller)){
      case (null){
          return false;
      };
      case(?datetxt) {

        switch(_textToDateType(datetxt)){
          case(null){
              return false;
          };
          case(?date){

            if(Date.isFutureDate(date) == false){
              return false;
            }else{
              return true;
            };

          };
              
        };
          
        };
    };
  };

  private func _deleteDropEvent(mark : Text) : Bool {
    switch(Map.get(ephemeral_drop_events, thash, mark)){//event must exist
      case(null){
        return false;
      };
      case(?evt){
        Map.delete(ephemeral_drop_events, thash, mark);
        Map.delete(ephemeral_drop_event_values, thash, evt);
        Map.delete(ephemeral_drop_event_slots, thash, evt);
        Map.delete(ephemeral_drop_event_urls, thash, evt);
        return true;
      };
    };
  };

  private func _updateDropEvent(mark : Text, uuid : Text, date : Text, dropValue : Nat, slotCount : Nat, imgUrl : Text) : Bool {
    switch(Map.get(ephemeral_drop_events, thash, mark)){//event must exist
      case(null){
        Map.set(ephemeral_drop_events, thash, mark, uuid);
        Map.set(ephemeral_drop_event_dates, thash, uuid, date);
        Map.set(ephemeral_drop_event_values, thash, uuid, dropValue);
        Map.set(ephemeral_drop_event_slots, thash, uuid, slotCount);
        Map.set(ephemeral_drop_event_urls, thash, uuid, imgUrl);
        return true;
      };
      case(?evt){
        return false;
      };
    };
  };

  private func _updateEphemeralDrop( drop_id : Text, date : Text, slot :Nat, val : Nat, subaccount : ?[Nat8]) : Bool {
    switch(Map.get(ephemeral_drops, thash, drop_id)){
      case(null){
        return false;
      };
      case(?drop){
        Map.set(ephemeral_drops, thash, drop_id, date);
        Map.set(ephemeral_drop_accounts, thash, drop_id, subaccount);
        Map.set(ephemeral_drop_slots, thash, drop_id, slot);
        Map.set(ephemeral_drop_values, thash, drop_id, val);
        Map.set(ephemeral_drop_event_slots, thash, drop_id, Nat.sub(slot, 1));
        return true;
      };
    };
    
  };

  private func _deletEphemeralDrop(drop_id : Text) : Bool {
    switch(Map.get(ephemeral_drops, thash, drop_id)){
      case(null){
        return false;
      };
      case(?drop){
        Map.delete(ephemeral_drops, thash, drop_id);
        Map.delete(ephemeral_drop_accounts, thash, drop_id);
        Map.delete(ephemeral_drop_slots, thash, drop_id);
        Map.delete(ephemeral_drop_values, thash, drop_id);
        return true;
      };
    };
    
  };

  public shared func deleteEphemeralDropEvent( args : ICRC1.Account, mark : Text) : async Bool{
    switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(args.owner) })) {//must be a generator
      case (null) {
          return false;
      };
      case (?val) {

        switch (Map.get(generator_marks, phash, args.owner)){//must have a mark
          case (null){
            return false;
          };
          case(?m) {
            return _deleteDropEvent(mark);
          };
        };
        
      };
    };
  };

/**
 * Create Ephemeral Drop Event:
 *
 * @param {Nat} amount of Oro to be burned as payment for drop creation.
 * @param {Text} date The date of the event in the format 'YYYY-MM-DD HH:MM:SS.SSS'.
 * @param {Nat} dropValue The value of the drop in atomic units.
 * @param {Nat} slotCount The number of slots for the event.
 * @param {Text} mark The unique identifier for the event.
 * @param {Text} imgUrl The URL of the image associated with the event.
 *
 * This method allows authorized generators to create a new ephemeral drop event. It first checks if the caller is a valid generator. If not, it returns an error message. Then it verifies that the mark provided exists and that there is no existing drop event with the same mark. If all conditions are met, it burns the specified amount of tokens and creates a new drop event with the given parameters.
 */
  public shared ({ caller }) func createEphemeralDropEvent( amount : Nat, date : Types.DateType, dropValue : Nat, slotCount : Nat, mark : Text, imgUrl : Text) : async ICRC2.TransferFromResponse {
    switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(caller) })) {//must be a generator
      case (null) {
        D.trap("Unauthorized.");
      };
      case (?val) {

        switch (Map.get(generator_marks, phash, caller)){//must have a mark
            case (null){
              D.trap("Unauthorized.");
            };
            case(?m) {
              switch(Map.get(ephemeral_drop_events, thash, mark)){//event must not exist
                case(null){
                  if(_isPngUrl(imgUrl)){
                    if(amount >= Nat.mul(Nat.div(dropValue, 100), ephemeralDropCost)){
                      let g = Source.Source();
                      let uuid = UUID.toText(await g.new());
                      let d = _dateTimeToText(date);
                      if(_updateDropEvent(mark, uuid, d, dropValue, slotCount, imgUrl)){
                        return await _burnTokens(caller, amount);
                      }else{
                        D.trap("Failed to update drop event data.");
                      };
                    }else{
                      D.trap("Burn amount is insufficient to create Drop Event.");
                    };
                    
                      
                  }else{
                    D.trap("Mark doesn't exist.");
                  };
                };
                case(?evt){
                  D.trap("Drop event exists already.");
                };
              };

            };
        };
      };
    };
    
  };

  private func _textToDateType(text : Text) : ?Types.DateType {

    let arr = Iter.toArray(Text.split(text, #char '|'));
    let size = Array.size(arr);

    if(size != 6){
      return null;
    };

    return switch(Nat.fromText(arr[0])){
      case(null){return null};
      case(?year){
        switch(Nat.fromText(arr[1])){
          case(null){return null};
          case(?month){
            switch(Nat.fromText(arr[2])){
              case(null){return null};
              case(?day){
                switch(Nat.fromText(arr[3])){
                  case(null){return null};
                  case(?hour){
                    switch(Nat.fromText(arr[4])){
                      case(null){return null};
                      case(?minute){
                        switch(Nat.fromText(arr[5])){
                          case(null){return null};
                          case(?nanosecond){
                            ? {
                                year = year;
                                month = month;
                                day = day;
                                hour = hour;
                                minute = minute;
                                nanosecond = nanosecond;
                            };
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

  };

  private func _dateTimeToText(date : Types.DateType) : Text {
    return Nat.toText(date.year) # "|" # Nat.toText(date.month) # "|" # Nat.toText(date.day) # "|" # Nat.toText(date.hour) # "|" # Nat.toText(date.minute) # "|" # Nat.toText(date.nanosecond);
  };

  private func _dateComponentsToText(date : Components.Components) : Text {
    let dt : Types.DateType = {
      year = Nat32.toNat(Nat32.fromIntWrap(date.year));
      month = Nat32.toNat(Nat32.fromIntWrap(date.month));
      day = Nat32.toNat(Nat32.fromIntWrap(date.day));
      hour = Nat32.toNat(Nat32.fromIntWrap(date.hour));
      minute = Nat32.toNat(Nat32.fromIntWrap(date.minute));
      nanosecond = Nat32.toNat(Nat32.fromIntWrap(date.nanosecond));
    };
    return _dateTimeToText(dt);
  };

/**
 * Delete Ephemeral Drop:
 *
 * @param {ICRC1.Account} args The account to check.
 * @param {Text} mark The unique identifier for the drop.
 * @param {Text} targetAcct The target account that should own the drop.
 *
 * This method allows authorized generators to delete an ephemeral drop. It first checks if the caller is a valid generator and owns the mark associated with the drop. If not, it returns an error message. Then it verifies that the drop exists and that the target account matches the owner of the drop. If all conditions are met, it deletes the drop.
 */
  public shared func deleteEphemeralDrop( args : ICRC1.Account, mark : Text, targetAcct : Text ) : async Bool {
    if(targetAcct != Principal.toText(args.owner)){//target account cannot be the creator of drop

      switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(args.owner) })) {//must be the owner of the mark
        case (null) {
          D.trap("Unauthorized.");
          return false;
        };
        case (?val) {

          let delimit = mark # "|";
          let key = Text.concat(delimit, targetAcct);

          switch (Map.get(ephemeral_drops, thash, key)) {//drop must not exist
            case (null) {
              D.trap("Drop already exists.");
              return false;
            };
            case (?val) {
              return _deletEphemeralDrop(key);
            };
          };
        };
      };

    }else{
      return false;
    };
  };

  /**
  * Join Ephemeral Drop:
  *
  * @param {Types.DropAccount} args The mint account arguments.
  * @param {Text} mark The unique identifier for the drop.
  *
  * This method allows users to join an existing ephemeral drop. It first checks if the drop exists and that the user is not already a part of it. If all conditions are met, it updates the drop data accordingly.
  */
  public shared func joinEphemeralDrop( args : Types.DropAccount, mark : Text ) : async ? Types.EphemeralDrop {
    switch (Map.get(ephemeral_drop_events, thash, mark)) {
      case(null){
          D.trap("Mark doesn't exist.");
        };
      case(?event){

        switch (Map.get(ephemeral_drop_event_slots, thash, event)) {
          case(null){
            D.trap("Invalid slot.");
          };
          case(?slot){
            let key = _ephemeralDropKey(Principal.toText(args.owner), mark);

            switch (Map.get(ephemeral_drop_event_dates, thash, event)) {

              case(null){
                D.trap("Drop target not found.");
              };
              case(?d){
                switch (Map.get(ephemeral_drops, thash, key)) {//drop must not exist

                  case (null) {
                    if(Nat.greater(slot, 0)){

                      switch (Map.get(ephemeral_drop_values, thash, key)) {

                        case(null){
                          D.trap("Drop value not found.");
                        };
                        case(?val){
                              
                          if(_updateEphemeralDrop( key, d, slot, val, args.subaccount)){
                            ?{
                              event_id = event;
                              date = d;
                              drop_id = key;
                              slot = slot;
                              amount = val;
                            };
                          }else{
                            D.trap("Drop data update failed.");
                          };

                        };
                      };
                                
                    }else{
                      D.trap("All slots filled.");
                    };
                              
                  };
                  case (?val) {
                    D.trap("Drop already exists.");
                  };

                };
              };
            };
            
          };
        };
              
      };
    };
  };

  /**
  * Get Ephemeral Drop Event ID:
  *
  * @param {Text} mark The unique identifier for the drop.
  *
  * This method retrieves the event ID associated with a given ephemeral drop mark. If no event exists, it returns an error message.
  */
  public query func getEphemeralDropEventId( mark : Text ) : async Text {
    switch (Map.get(ephemeral_drop_events, thash, mark)) {
      case(null){
        return "No event found."
      };
      case(?event){
        return event;
      };
    };
  };

/**
 * Check if an ephemeral drop is ready:
 *
 * @param {ICRC1.Account} args The account to check.
 * @param {Text} mark The unique identifier for the drop.
 *
 * This method checks if an ephemeral drop is ready by verifying that it has a date in the future and that the account owns the drop. If all conditions are met, it returns True; otherwise, it returns False.
 */
  public query func isEphemeralDropReady( args : ICRC1.Account, mark : Text ) : async Bool {
    let key = _ephemeralDropKey(Principal.toText(args.owner), mark);

    switch (Map.get(ephemeral_drops, thash, key)) {
      case (null) {
        D.trap("Mark doesn't exist.");
        return false;
      };
      case (?val) {
        switch(_dateType( Principal.toText(args.owner), mark)) {
          case (null)  {
            return false;
           };
          case (?date)  {
            return Date.isFutureDate(date);
          };
        };
      };
    };

  };

  /**
  * Show Ephemeral Drop Date:
  *
  * @param {ICRC1.Account} args The account to check.
  * @param {Text} mark The unique identifier for the drop.
  *
  * This method displays the date associated with a given ephemeral drop mark. If no date exists, it returns an error message.
  */
  public query func showEphemeralDropDate( args : ICRC1.Account, mark : Text ) : async Text {
    let key = _ephemeralDropKey(Principal.toText(args.owner), mark);

    switch (Map.get(ephemeral_drops, thash, key)) {
      case (null) {
        return "Mark doesn't exist.";
      };
      case (?val) {
        switch(_dateType( Principal.toText(args.owner), mark)) {
          case (null)  {
            return "Something went wrong.";
           };
          case (?date)  {
            return Date.show(date);
          };
        };
      };
    };

  };


  private func ephemeralDropMint(owner : Principal, key : Text, amount : Nat) : async ?Types.MintEphemeral {
    return ?{
            target = switch(Map.get<Text, ?[Nat8]>(ephemeral_drop_accounts, thash, key)){
              case(null){
                ?{
                  owner = owner;
                  subaccount = null;
                };
              };
              case(?val) {
                ?{
                  owner = owner;
                  subaccount = switch(val){
                    case(null) null;
                    case(?val) ?val;
                  };
                }
              };
            };
            amount = amount+oroFee;
          };
  };

  private func mintEphemeralDropTokens(owner : Principal, key : Text, amount : Nat, mark : Text ) : async ICRC1.TransferResult {
    let args :  ?Types.MintEphemeral = await ephemeralDropMint(owner, key, amount);
    var memo : Blob = Text.encodeUtf8(mark);
 
    switch(args){
      case(null){
        Debug.print("Something went wrong with ephemeral mint args!");
        D.trap("Something went wrong with ephemeral mint args.");
      };
      case(?arg){

        let newtokens =  await* icrc1().mint_tokens(Principal.fromActor(this), {
          to = switch(arg.target){
              case(null){
                {
                  owner = owner;
                  subaccount = null;
                }
              };
              case(?val) {
                {
                  owner = val.owner;
                  subaccount = switch(val.subaccount){
                    case(null) null;
                    case(?val) ?Blob.fromArray(val);
                  };
                }
              };
            };               // The account receiving the newly minted tokens.
          amount = amount;           // The number of tokens to mint.
          created_at_time = ?time64();
          memo = ?(memo);
        });

        return switch(newtokens){
          case(#trappable(val)) val;
          case(#awaited(val)) val;
          case(#err(#trappable(err))) D.trap(err);
          case(#err(#awaited(err))) D.trap(err);
        };
        
      };
    };

  };

  /**
  * Collect Ephemeral Drop:
  *
  * @param {Text} mark The unique identifier for the drop.
  *
  * This method collects an ephemeral drop by verifying that it exists, 
  * if its date is in the past, and the account owns the drop, 
  * it mints tokens and updates the drop status; otherwise, it returns an error message.
  */
  public shared ({ caller }) func collectEphemeralDrop( mark : Text ) : async ICRC1.TransferResult {
    let key = _ephemeralDropKey(Principal.toText(caller), mark);

    switch (Map.get(ephemeral_drops, thash, key)) {
      case (null) {
        D.trap("Mark doesn't exist.");
      };
      case (?val) {
        switch(_dateType( Principal.toText(caller), mark)) {
          case (null)  {
            D.trap("Invalid Date.");
           };
          case (?date)  {
            if (Date.isFutureDate(date)){
              D.trap("Drop not ready.");
            }else{
              switch(Map.get(ephemeral_drop_values, thash, key)){
                case(null){
                  D.trap("Value not found.");
                };
                case(?amount){

                  var result : ICRC1.TransferResult = await mintEphemeralDropTokens(caller, key, amount, mark);
                  let block = switch(result){
                  case(#Ok(block)){
                    if(_deletEphemeralDrop(key) == false){
                      D.trap("Something went wrong, couldnt update drop status.");
                    }else{
                      block;
                    };
                  };
                  case(#Err(err)){
                    D.trap("cannot transfer from failed" # debug_show(err));
                  };
                };

                return result;
                };
              };

            };
          };
        };
      };
    };

  };

  /**
  * Join Generation:
  *
  * @param {ICRC1.Account} args The account to check.
  * @param {Text} mark The unique identifier for the mint generator.
  * @param {Text} moniker The unique identifier for the generation.
  *
  * This method joins a generation by verifying that the generation exists 
  * and that the account owns the generation. If all conditions are met, 
  * it burns tokens and updates the generation status; otherwise, it returns an error message.
  */
  public shared ({ caller }) func joinGeneration(args : ICRC1.Account, mark : Text, moniker : Text) : async ICRC2.TransferFromResponse {
    switch (Map.get(mark_generators, thash, mark)){//generation mark must exist
      case (null){
        D.trap("Mark doesn't exist.");
      };
      case(?generator) {
        let key = _generationKey(Principal.toText(args.owner), moniker);
        switch (Map.get(generations, thash, key)){//generation moniker must not exist
          case (null){
            Map.set(generations, thash, key, mark);
            return await _burnTokens(caller, generationJoinCost);
          };
          case(?m) {
            D.trap("Moniker already exists.");
          };
        };
      };
    };

  };

  /**
  * Check if Account is in Generation:
  *
  * @param {ICRC1.Account} args The account to check.
  * @param {Text} moniker The unique identifier for the generation.
  *
  * This method checks whether an account is currently participating in a given generation. 
  * If it is, it returns the generation mark; otherwise, it returns an error message.
  */
  public query func isInGeneration(args : ICRC1.Account, moniker : Text)  : async ?Text {
    let key = _generationKey(Principal.toText(args.owner), moniker);
    return Map.get(generations, thash, key);
  };

  /**
  * Set Mark Logo:
  *
  * @param {ICRC1.Account} args The account to set the logo for.
  * @param {Types.MarkType} markType The type of mark containing the logo URL.
  *
  * This method sets a logo for a given mark, ensuring that only authorized accounts 
  * can perform this action and validating the format of the logo URL. If successful, 
  * it updates the map with the new logo; otherwise, it returns an error message.
  */
  public shared func setMarkLogo(args : ICRC1.Account, markType : Types.MarkType) : async Bool {
    if(_isPngUrl(markType.logoUrl)){

      // Check if the account is authorized to set a logo for this mark
      switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(args.owner) })) {
        case (null) {
          D.trap("Unauthorized.");
        };
        case (?val) {
          // Update the map with the new logo
          Map.set(mark_logos, thash, markType.mark, markType.logoUrl);
          return true;
        };
      };

    }else{
      D.trap("Logo url isn't the correct format.");
      return false;
    };

  };

  /**
  * Check if account is a generator:
  *
  * @param {ICRC1.Account} args The account to check.
  *
  * This method checks whether an account is authorized as a generator. 
  * It does this by searching the 'generators' map for the given owner's principal, 
  * returning true if found and false otherwise.
  */
  public query func isGenerator(args : ICRC1.Account)  : async Bool{
    switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(args.owner) })) {
      case (null) {
        return false;
      };
      case (?val) {
        return true;
      };
    };
  };

  /**
  * Retrieve the minimum ICP tokens required for a drop.
  *
  * This method retrieves and returns the minimum ICP tokens required for a drop, expressed as a floating-point number.
  */
  public query func icpMinimumTokensRequired() : async Float{
    return Float.fromInt(icpMinimum / 100_000_000);
  };

  /**
  * Retrieve the current ICP exchange rate.
  *
  * This method retrieves and returns the current ICP exchange rate, expressed as a floating-point number).
  */
  public query func getIcpExchangeRate() : async Float{
    return Float.fromInt(icpExchangeRate / 10_000_000_000_000_000);
  };

  /**
  * Retrieve the total amount of ICP tokens collected in the treasury.
  *
  * This method retrieves and returns the total amount of ICP tokens collected in the treasury, expressed as a floating-point number.
  */
  public query func icpTreasuryTotalCollected() : async Float{
    return Float.fromInt(icpTreasury / 100_000_000);
  };

  /**
   * Retrieve the minimum ETH tokens required for a drop.
   *
   * @return The minimum ETH tokens required for a drop, expressed as a floating-point number.
   */
  public query func ethMinimumTokensRequired() : async Float{
    return Float.fromInt(ethMinimum / 100_000_000);
  };

  /**
  * Retrieve the current CK-ETH exchange rate.
  *
  * This method retrieves and returns the current CK-ETH exchange rate, expressed as a floating-point number.
  */
  public query func getckEthExchangeRate() : async Float{
    return Float.fromInt(ckEthExchangeRate / 10_000_000_000_000_000);
  };

  /**
   * Retrieve the total amount of ETH tokens collected in the treasury.
   *
   * @return The total amount of ETH tokens collected in the treasury, expressed as a floating-point number.
   */
  public query func ethTreasuryTotalCollected() : async Float{
    return Float.fromInt(ethTreasury / 100_000_000);
  };

  /**
   * Retrieve the minimum Bitcoin tokens required for a drop.
   *
   * This method retrieves and returns the minimum Bitcoin tokens required for a drop, expressed as a floating-point number.
   */
  public query func btcMinimumTokensRequired() : async Float{
    return Float.fromInt(btcMinimum / 100_000_000);
  };
  /**
  *
  * This method retrieves and returns the current CK-BTC exchange rate, expressed as a floating-point number
  */
  public query func getckBtcExchangeRate() : async Float{
    return Float.fromInt(ckBtcExchangeRate / 10_000_000_000_000_000);
  };

  /**
   * Retrieve the total amount of Bitcoin tokens collected in the treasury.
   *
   * @return The total amount of Bitcoin tokens collected in the treasury, expressed as a floating-point number.
   */
  public query func btcTreasuryTotalCollected() : async Float{
    return Float.fromInt(btcTreasury / 100_000_000);
  };

  /**
  * Retrieve the total number of mints performed.
  *
  * This method retrieves and returns the total number of mints performed, providing insight into the overall minting activity.
  */
  public query func getNumberOfGenerators() : async Nat{
    return generatorCount;
  };

  /**
  * Retrieve the current reward cycle:
  *
  * @return The current reward cycle as a natural number.
  *
  * This method retrieves and returns the current reward cycle, providing insight into the overall minting activity.
  */
  public query func getCurrentRewardCycle() : async Nat{
    return ephemeralRewardCycle;
  };

  /**
   * Retrieve the total number of ephemeral mints performed:
   *
   * This method retrieves and returns the total number of ephemeral mints performed, providing insight into the overall minting activity.
   */
  public query func getNumberOfEphemeralMints() : async Nat{
    return ephemeralMintCount;
  };

  /**
  * Retrieves the balance of an account.
  *
  * This method retrieves and returns the balance of a given account, expressed as a floating-point number.
  *
  * @param {ICRC1.Account} args The account to retrieve the balance for.
  */
  public shared func balance(args : ICRC1.Account) : async Float{
    let balance = await icrc1_balance_of(
      {
          owner = args.owner;
          subaccount = args.subaccount;
      }
    );
    return Float.fromInt(balance / 10_000_000_000_000_000)
  };

  /**
  * Retrieves the total supply of tokens.
  *
  * This method retrieves and returns the total supply of tokens, expressed as a floating-point number.
  */
  public shared func total_supply() : async Float{
    let balance = await icrc1_total_supply(); 
    return Float.fromInt(balance / 10_000_000_000_000_000)
  };

  /**
  * Retrieves the coin allocation by mark for a given account.
  *
  * This method retrieves and returns the minted balance for a specified mark, expressed as a floating-point number.
  *
  * @param {ICRC1.Account} args The account to retrieve the minted balance for.
  * @param {Text} mark The mark for which to retrieve the minted balance.
  */
  public shared func coinAllocationByMark(args : ICRC1.Account, mark : Text) : async Float{
      switch (Map.get(mark_coin_allocation, thash, mark)) {
        case (null) {
          D.trap("Mark doesn't exist.");
        };
        case (?balance) {
          return Float.fromInt(balance / 10_000_000_000_000_000);
        };
      };
  };

   /**
  * Retrieves the coin allocation type (ICP, ETH, BTC) by mark for a given account.
  *
  * This method retrieves and returns the generator token allocation typefor a specified mark, expressed as a string.
  *
  * @param {ICRC1.Account} args The account to retrieve the coin type.
  * @param {Text} mark The mark for which to retrieve the coin type.
  */
  public shared func coinAllocationTypeByMark(args : ICRC1.Account, mark : Text) : async Text{
      switch (Map.get(mark_allocation_type, thash, mark)) {
        case (null) {
          D.trap("Mark doesn't exist.");
        };
        case (?coin) {
          return coin;
        };
      };
  };
  
/**
 * Retrieves the total ephemeral minted balance.
 *
 * This method retrieves and returns the total ephemeral minted balance, expressed as a floating-point number.
 */
  public shared func totalEphemeralMintedBalance() : async Float{
    return Float.fromInt(ephemeralMintedBalance)
  };

  /**
   * Retrieves the total generator minted balance.
   *
   * This method retrieves and returns the total generator minted balance, expressed as a floating-point number.
   */
  public shared func totalGeneratorMintedBalance() : async Float{
    return Float.fromInt(generatorMintedBalance)
  };

    /**
   * Retrieves the total ICP Network take.
   *
   * This method retrieves and returns the total icp network take.
   */
  public shared func totalICPNetworkTake() : async Nat{
    return ICPNetworkTake
  };

    /**
   * Retrieves the total ETH Network take.
   *
   * This method retrieves and returns the total eth network take.
   */
  public shared func totalETHNetworkTake() : async Nat{
    return ETHNetworkTake
  };

    /**
   * Retrieves the total BTC Network take.
   *
   * This method retrieves and returns the total btc network take.
   */
  public shared func totalBTCNetworkTake() : async Nat{
    return BTCNetworkTake
  };

  /**
  * Retrieves the current ephemeral reward.
  *
  * This method retrieves and returns the current ephemeral reward, providing insight into the overall minting activity.
  *
  * @return The current ephemeral reward as a natural number.
  */
  public query func currentEphemeralReward() : async Nat{
    return ephemeralReward;
  };

  public shared ({ caller }) func burn(args : ICRC1.BurnArgs) : async ICRC1.TransferResult {
      switch( await*  icrc1().burn_tokens(caller, args, false)){
        case(#trappable(val)) val;
        case(#awaited(val)) val;
        case(#err(#trappable(err))) D.trap(err);
        case(#err(#awaited(err))) D.trap(err);
      };
  };

  public query ({ caller }) func icrc2_allowance(args: ICRC2.AllowanceArgs) : async ICRC2.Allowance {
      return icrc2().allowance(args.spender, args.account, false);
  };

  public shared ({ caller }) func icrc2_approve(args : ICRC2.ApproveArgs) : async ICRC2.ApproveResponse {
      switch(await*  icrc2().approve_transfers(caller, args, false, null)){
        case(#trappable(val)) val;
        case(#awaited(val)) val;
        case(#err(#trappable(err))) D.trap(err);
        case(#err(#awaited(err))) D.trap(err);
      };
  };

  public shared ({ caller }) func icrc2_transfer_from(args : ICRC2.TransferFromArgs) : async ICRC2.TransferFromResponse {
      switch(await* icrc2().transfer_tokens_from(caller, args, null)){
        case(#trappable(val)) val;
        case(#awaited(val)) val;
        case(#err(#trappable(err))) D.trap(err);
        case(#err(#awaited(err))) D.trap(err);
      };
  };

  public query func icrc3_get_blocks(args: ICRC3.GetBlocksArgs) : async ICRC3.GetBlocksResult{
    return icrc3().get_blocks(args);
  };

  public query func icrc3_get_archives(args: ICRC3.GetArchivesArgs) : async ICRC3.GetArchivesResult{
    return icrc3().get_archives(args);
  };

  public query func icrc3_get_tip_certificate() : async ?ICRC3.DataCertificate {
    return icrc3().get_tip_certificate();
  };

  public query func icrc3_supported_block_types() : async [ICRC3.BlockType] {
    return icrc3().supported_block_types();
  };

  public query func get_tip() : async ICRC3.Tip {
    return icrc3().get_tip();
  };

  public shared ({ caller }) func icrc4_transfer_batch(args: ICRC4.TransferBatchArgs) : async ICRC4.TransferBatchResults {
      switch(await* icrc4().transfer_batch_tokens(caller, args, null, null)){
        case(#trappable(val)) val;
        case(#awaited(val)) val;
        case(#err(#trappable(err))) err;
        case(#err(#awaited(err))) err;
      };
  };

  public shared query func icrc4_balance_of_batch(request : ICRC4.BalanceQueryArgs) : async ICRC4.BalanceQueryResult {
      icrc4().balance_of_batch(request);
  };

  public shared query func icrc4_maximum_update_batch_size() : async ?Nat {
      ?icrc4().get_state().ledger_info.max_transfers;
  };

  public shared query func icrc4_maximum_query_batch_size() : async ?Nat {
      ?icrc4().get_state().ledger_info.max_balances;
  };

  public shared ({ caller }) func admin_update_owner(new_owner : Principal) : async Bool {
    if(caller != owner){ D.trap("Unauthorized")};
    owner := new_owner;
    return true;
  };

  public shared ({ caller }) func admin_update_icrc1(requests : [ICRC1.UpdateLedgerInfoRequest]) : async [Bool] {
    if(caller != owner){ D.trap("Unauthorized")};
    return icrc1().update_ledger_info(requests);
  };

  public shared ({ caller }) func admin_update_icrc2(requests : [ICRC2.UpdateLedgerInfoRequest]) : async [Bool] {
    if(caller != owner){ D.trap("Unauthorized")};
    return icrc2().update_ledger_info(requests);
  };

  public shared ({ caller }) func admin_update_icrc4(requests : [ICRC4.UpdateLedgerInfoRequest]) : async [Bool] {
    if(caller != owner){ D.trap("Unauthorized")};
    return icrc4().update_ledger_info(requests);
  };

  /* /// Uncomment this code to establish have icrc1 notify you when a transaction has occured.
  private func transfer_listener(trx: ICRC1.Transaction, trxid: Nat) : () {

  };

  /// Uncomment this code to establish have icrc1 notify you when a transaction has occured.
  private func approval_listener(trx: ICRC2.TokenApprovalNotification, trxid: Nat) : () {

  };

  /// Uncomment this code to establish have icrc1 notify you when a transaction has occured.
  private func transfer_from_listener(trx: ICRC2.TransferFromNotification, trxid: Nat) : () {

  }; */

  private stable var _init = false;
  public shared(msg) func admin_init() : async () {
    //can only be called once


    if(_init == false){
      //ensure metadata has been registered
      let test1 = icrc1().metadata();
      let test2 = icrc2().metadata();
      let test4 = icrc4().metadata();
      let test3 = icrc3().stats();

      //uncomment the following line to register the transfer_listener
      //icrc1().register_token_transferred_listener("my_namespace", transfer_listener);

      //uncomment the following line to register the transfer_listener
      //icrc2().register_token_approved_listener("my_namespace", approval_listener);

      //uncomment the following line to register the transfer_listener
      //icrc1().register_transfer_from_listener("my_namespace", transfer_from_listener);
    };
    _init := true;
  };


  // Deposit cycles into this canister.
  public shared func deposit_cycles() : async () {
      let amount = ExperimentalCycles.available();
      let accepted = ExperimentalCycles.accept<system>(amount);
      assert (accepted == amount);
  };

  system func postupgrade() {
    //re wire up the listener after upgrade
    //uncomment the following line to register the transfer_listener
      //icrc1().register_token_transferred_listener("my_namespace", transfer_listener);

      //uncomment the following line to register the transfer_listener
      //icrc2().register_token_approved_listener("my_namespace", approval_listener);

      //uncomment the following line to register the transfer_listener
      //icrc1().register_transfer_from_listener("my_namespace", transfer_from_listener);
  };

};
