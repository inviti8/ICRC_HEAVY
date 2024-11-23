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
      name = ?"Oro";
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
  stable var mintedCount : Nat = 0;

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
  let mark_logos = Map.new<Text, Text>(thash);
  let marked_mint_balances = Map.new<Text, Nat>(thash);

  stable var generatorMintedBalance : Nat = 0;

  //minters who create a mark have ability to create token drop events & board posts at burn cost
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
  

  let message_board = Map.new<Text, Text>(thash);
  let message_board_urls = Map.new<Text, Text>(thash);
  //cost to post message starts at 100% burn of tokens
  stable var messageBoardCost : Nat = 100;


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

  system func heartbeat() : async () {
    if (tick % ephemeralRewardInterval == 0) {
      Debug.print("mintedCount = " # debug_show(mintedCount));
      Debug.print("maturity = " # debug_show(maturity));
      if(mintedCount >= maturity){//at maturity ephemeral mint starts
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

  private func mintInflationaryTokens(args : Types.MintFromArgs, caller : Principal, memo : Blob ) : async ICRC1.TransferResult {
    
    var exchangeRate : Nat = icpExchangeRate;
    if(mintedCount < maturity){//at maturity inflation stops
      switch (args.coin) {
        case (#ICP){
          exchangeRate-=icpInflation;
          icpExchangeRate-=icpInflation;
        };
        case (#ETH){
          exchangeRate := ckEthExchangeRate;
          exchangeRate-=ckEthInflation;
          ckEthExchangeRate-=ckEthInflation;
        };
        case (#BTC){
          exchangeRate := ckBtcExchangeRate;
          exchangeRate-=ckBtcInflation;
          ckBtcExchangeRate-=ckBtcInflation;
        };
      };
    };
    
    var mintingAmount : Nat = exchangeRate * (args.amount / 100_000_000);
    generatorMintedBalance := generatorMintedBalance + mintingAmount;
    mintedCount := mintedCount + 1;

    let newtokens =  await* icrc1().mint_tokens(Principal.fromActor(this), {
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

  public shared ({ caller }) func mintFromToken(args : Types.MintFromArgs) : async ICRC1.TransferResult {

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

      switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(caller) })) {
        case (null) {};
        case (?val) {
          D.trap("Only one mint per Principal is allowed.");
        };
      };

      var memo : Blob = Text.encodeUtf8("UNMARKED");
      var marked : Bool = false;

      switch (args.mintMark){//Minter can add custom mark to coins
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

      switch (args.coin) {
        case (#ICP){

          let ICPLedger : ICPTypes.Service = actor(ICP_LEDGER);

          // check ICP balance of the callers dedicated account
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

          // check ICP balance of the callers dedicated account
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
              block;
            };
            case(#Err(err)){
                D.trap("cannot transfer from failed" # debug_show(err));
            };
          };

        };
        case (#BTC){

          let BTCLedger : CkBTCTypes.Service = actor(CK_BTC_LEDGER);

          // check ICP balance of the callers dedicated account
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
          Map.set(generators, nhash, mintedCount, Principal.toText(caller));//Add minter to reconstruct
          Map.set(generator_principals, phash, caller, mintedCount);//Add minter to list for ephemeral minting
          Map.set(generator_accounts, nhash, mintedCount, args.source_subaccount);//Add minter to list for ephemeral minting
          switch(Text.decodeUtf8(memo)){
            case(null){};
            case(?mem){
              Map.set(marked_mint_balances, thash, mem, args.amount);
            };
          };
          if(marked){
            Map.set(generator_marks, phash, caller, Text.decodeUtf8(memo));//if coin is marked add memo to map
          };
          block;
        };
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      return result;
  };

  public shared ({ caller }) func withdrawICP(amount : Nat) : async ICPTypes.Result_2 {
    
      if(caller != owner){ D.trap("Unauthorized")};

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
              owner = caller;//THIS MUST BE REPLACED WITH HARDCODED ADDRESS
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

  public shared ({ caller }) func withdrawCkETH(amount : Nat) : async CkETHTypes.Result_2 {

      if(caller != owner){ D.trap("Unauthorized")};

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
              owner = caller;//THIS MUST BE REPLACED WITH HARDCODED ADDRESS
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

  public shared ({ caller }) func withdrawCkBTC(amount : Nat) : async CkBTCTypes.Result_2 {

      if(caller != owner){ D.trap("Unauthorized")};

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
              owner = caller;//THIS MUST BE REPLACED WITH HARDCODED ADDRESS
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

  public query func isTokenFrozen() : async ? Bool{
    return do ? {
        Date.isFutureDate(dispensation);
    };
  };

  public query func getGeneratorEpoch(args : ICRC1.Account) : async ?Nat{
    return Map.get(generator_principals, phash, args.owner);
  };

  public query func getMarkLogo(mark : Text) : async ?Text{
    return Map.get(mark_logos, thash, mark);
  };

  private func _ephemeralDropKey( acct : Text, mark : Text ) : Text{
    let delimit = mark # "|";
    return Text.concat(delimit, acct);
  };

  private func _isPngUrl(url : Text) : Bool {
    return (Text.startsWith(url, #text "https://" ) and Text.endsWith(url, #text ".png"))
  };

  private func _dateType( acct : Text, mark : Text ) : ? Types.DateType{
    let key = _ephemeralDropKey(acct, mark);

    switch (Map.get(ephemeral_drops, thash, key)) {
      case (null) {
        return null;
      };
      case (?val) {
        let arr = Iter.toArray(Text.split(val, #char '|'));
        switch(Nat.fromText(arr[0])){
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
                            switch(Nat.fromText(arr[0])){
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

  public shared ({ caller }) func createEphemeralDropEvent( args : ICRC1.BurnArgs, date : Types.DateType, dropValue : Nat, slotCount : Nat, mark : Text, imgUrl : Text) : async ICRC1.TransferResult{
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
                    if(args.amount >= Nat.mul(Nat.div(dropValue, 100), ephemeralDropCost)){
                        switch( await*  icrc1().burn_tokens(caller, args, false)){
                          case(#trappable(val)){
                              D.trap("Something went wrong.");
                          };
                          case(#awaited(val)){
                              let g = Source.Source();
                              let uuid = UUID.toText(await g.new());
                              let d = Nat.toText(date.year) # "|" # Nat.toText(date.month) # "|" # Nat.toText(date.day) # "|" # Nat.toText(date.hour) # "|" # Nat.toText(date.minute) # "|" # Nat.toText(date.nanosecond);
                              if(_updateDropEvent(mark, uuid, d, dropValue, slotCount, imgUrl)){
                                val;
                              }else{
                                D.trap("Failed to update drop event data.");
                              };
                              
                          };
                          case(#err(#trappable(err))){D.trap(err)};
                          case(#err(#awaited(err))){D.trap(err)};
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

  public shared func deleteEphemeralDrop( args : ICRC1.Account, mark : Text, targetAcct : Text ) : async Bool{
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


  public shared func joinEphemeralDrop( args :Types.MintEphemeral, mark : Text ) : async ? Types.EphemeralDrop{
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
            switch(args.target){
              case(null){
                D.trap("All slots filled.");
              };
              case(?target){
                let key = _ephemeralDropKey(Principal.toText(target.owner), mark);

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
                              if(_updateEphemeralDrop( key, d, slot, val, target.subaccount)){
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
    };
  };

  public query func getEphemeralDropEventId( mark : Text ) : async Text{
    switch (Map.get(ephemeral_drop_events, thash, mark)) {
      case(null){
        return "No event found."
      };
      case(?event){
        return event;
      };
    };
  };

  public query func isEphemeralDropReady( args : ICRC1.Account, mark : Text ) : async Bool{
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

  public query func showEphemeralDropDate( args : ICRC1.Account, mark : Text ) : async Text{
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

  public shared func setMarkLogo(args : ICRC1.Account, markType : Types.MarkType) : async Bool{
    if(_isPngUrl(markType.logoUrl)){
      switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(args.owner) })) {
        case (null) {
          D.trap("Unauthorized.");
        };
        case (?val) {
          Map.set(mark_logos, thash, markType.mark, markType.logoUrl);
          return true;
        };
      };
    }else{
      D.trap("Logo url isn't the correct format.");
      return false;
    };
  };

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

  public query func icpMinimumTokensRequired() : async Float{
    return Float.fromInt(icpMinimum / 100_000_000);
  };

  public query func getIcpExchangeRate() : async Float{
    return Float.fromInt(icpExchangeRate / 10_000_000_000_000_000);
  };

  public query func icpTreasuryTotalCollected() : async Float{
    return Float.fromInt(icpTreasury / 100_000_000);
  };

  public query func ethMinimumTokensRequired() : async Float{
    return Float.fromInt(ethMinimum / 100_000_000);
  };

  public query func getckEthExchangeRate() : async Float{
    return Float.fromInt(ckEthExchangeRate / 10_000_000_000_000_000);
  };

  public query func ethTreasuryTotalCollected() : async Float{
    return Float.fromInt(ethTreasury / 100_000_000);
  };

  public query func btcMinimumTokensRequired() : async Float{
    return Float.fromInt(btcMinimum / 100_000_000);
  };

  public query func getckBtcExchangeRate() : async Float{
    return Float.fromInt(ckBtcExchangeRate / 10_000_000_000_000_000);
  };

  public query func btcTreasuryTotalCollected() : async Float{
    return Float.fromInt(btcTreasury / 100_000_000);
  };

  public query func getNumberOfMints() : async Nat{
    return mintedCount;
  };

  public query func getCurrentRewardCycle() : async Nat{
    return ephemeralRewardCycle;
  };

  public query func getNumberOfEphemeralMints() : async Nat{
    return ephemeralMintCount;
  };

  public shared func balance(args : ICRC1.Account) : async Float{
    let balance = await icrc1_balance_of(
      {
          owner = args.owner;
          subaccount = args.subaccount;
      }
    );
    return Float.fromInt(balance / 10_000_000_000_000_000)
  };

  public shared func total_supply() : async Float{
    let balance = await icrc1_total_supply(); 
    return Float.fromInt(balance / 10_000_000_000_000_000)
  };

  public shared func mintedBalanceByMark(args : ICRC1.Account, mark : Text ) : async Float{
    switch (Map.get(marked_mint_balances, thash, mark)) {
      case (null) {
        D.trap("Mark doesn't exist.");
      };
      case (?balance) {
        return Float.fromInt(balance / 10_000_000_000_000_000);
      };
    };
  };

  public shared func totalEphemeralMintedBalance() : async Float{
    return Float.fromInt(ephemeralMintedBalance)
  };

  public shared func totalGeneratorMintedBalance() : async Float{
    return Float.fromInt(generatorMintedBalance)
  };

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
