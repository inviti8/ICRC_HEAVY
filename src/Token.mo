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
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Map "mo:stable-hash-map/Map/Map";
import ICPTypes "ICPTypes";
import CkETHTypes "CkETHTypes";
import CkBTCTypes "CkBTCTypes";
import Date "Date";

shared ({ caller = _owner }) actor class Token  (args: ?{
    icrc1 : ?ICRC1.InitArgs;
    icrc2 : ?ICRC2.InitArgs;
    icrc3 : ICRC3.InitArgs; //already typed nullable
    icrc4 : ?ICRC4.InitArgs;
  }
) = this{

    let default_icrc1_args : ICRC1.InitArgs = {
      name = ?"Oro";
      symbol = ?"ORO";
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

  public shared ({ caller }) func mint(args : ICRC1.Mint) : async ICRC1.TransferResult {
      if(caller != owner){ D.trap("Unauthorized")};

      switch( await* icrc1().mint_tokens(caller, args)){
        case(#trappable(val)) val;
        case(#awaited(val)) val;
        case(#err(#trappable(err))) D.trap(err);
        case(#err(#awaited(err))) D.trap(err);
      };
  };

  //ORO SPECIFIC CODE
  private func time64() : Nat64 {
    Nat64.fromNat(Int.abs(Time.now()));
  };

  stable var icpExchangeRate : Nat = 8_0000_0000_0000_0000;//8 oro for 1 ICP
  //stable var icpInflation : Nat = 888_8888_8888;//subtracted with each new mint
  stable var icpInflation : Nat = 98_8888_8888_8888;//TEST
  stable var ckEthExchangeRate : Nat = icpExchangeRate*8;//64 oro for 1 ckETH
  stable var ckEthInflation : Nat = icpInflation*8;//subtracted with each new mint
  stable var ckBtcExchangeRate : Nat = icpExchangeRate*80;//640 oro for 1 ckBTC
  stable var ckBtcInflation : Nat = icpInflation*80;//subtracted with each new mint
  stable var mintedCount : Nat = 0;

  var tick = 0;
  var count = 0;
  //let interval = 88888888;
  let interval = 88;//TEST


  let ICP_LEDGER = "ryjl3-tyaaa-aaaaa-aaaba-cai";
  //let CK_ETH_LEDGER = "ss2fx-dyaaa-aaaar-qacoq-cai";
  let CK_ETH_LEDGER = "sh5u2-cqaaa-aaaar-qacna-cai";//testnet
  //let CK_BTC_LEDGER = "mxzaz-hqaaa-aaaar-qaada-cai";
  let CK_BTC_LEDGER = "mc6ru-gyaaa-aaaar-qaaaq-cai";//testnet

  let icpMinimum : Nat = 100000000;//e8s -> 1 icp token
  let icpFee : Nat = 10000;
  let ethMinimum : Nat = 100000000;//wei -> 0.1 eth
  let ethFee : Nat = 10;
  let btcMinimum : Nat = 979375;//sats -> 0.01 btc
  let btcFee : Nat = 10;
  
  //let maturity = 899999;//After this many mint calls, the price per oro in icp, eth, or btc becomes quite high
  let maturity = 89;//TEST
  //let dispensation = Date.create(#Year 2024, #August, #Day 8);//contract frozen until this date
  let dispensation = Date.create(#Year 2023, #August, #Day 8);//TEST
  stable var ephemeralMintCount : Nat = 0;

  let { nhash; phash } = Map;
  let generators = Map.new<Nat, Text>(nhash);
  let generator_principals = Map.new<Principal, Nat>(phash);
  let generator_accounts = Map.new<Nat, ?[Nat8]>(nhash);

  let gens : [var Text] = Array.init<Text>(maturity, "");

  private func ephemeralMint() : async ?Types.MintEphemeral {

    return switch(Map.get<Nat, Text>(generators, nhash, ephemeralMintCount)){//if generator exists, tokens are minted to them
        case(null){
          D.trap("Cannot Perform Ephemeral Mint.");
        };
        case(?gen){

          ?{
            target = switch(Map.get<Nat, ?[Nat8]>(generator_accounts, nhash, ephemeralMintCount)){
              case(null){
                ?{
                  owner = Principal.fromText(gen);
                  subaccount = null;
                }
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
            amount = 8;
          };
        };
      };
  };

  public shared func inc() : async () {
    tick := tick + 1;
    //Debug.print("count = " # debug_show(tick));
  };

  system func heartbeat() : async () {
    if (tick % interval == 0) {
      Debug.print("mintedCount = " # debug_show(mintedCount));
      Debug.print("maturity = " # debug_show(maturity));
      if(mintedCount >= maturity){//at maturity ephemeral mint starts
        Debug.print("should do ephemeral mint!");
        let args :  ?Types.MintEphemeral = await ephemeralMint();
        Debug.print("args = " # debug_show(args));
        switch(args){
          case(null){
            Debug.print("Args failed!");
            D.trap("Cannot Perform Ephemeral Mint.");
          };
          case(?val){
            var memo : Blob = Text.encodeUtf8("EPHEMERAL-->ORO");
            ignore await mintEphemeralTokens(val, memo);
            // let block = switch(mint){
            //   case(#Ok(block)){
            //     Debug.print("Ephemeral mint success!");
            //     block;
            //   };
            //   case(#Err(err)){
            //     Debug.print("Ephemeral mint failed!");
            //     D.trap("Ephemeral mint from failed" # debug_show(err));
            //   };
            // };
          };
        };
        //tick:=0;
      };
    };
    ignore inc();
  };

  public query func isTokenFrozen() : async ? Bool{
    return do ? {
        let unpacked = dispensation!;
        Date.isFutureDate(unpacked);
    };
  };

  private func mintEphemeralTokens(args : Types.MintEphemeral, memo : Blob ) : async ICRC1.TransferResult {
    let newtokens =  await* icrc1().mint_tokens(Principal.fromActor(this), {
        to = switch(args.target){
            case(null){
              D.trap("Mint target not found.");
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
        amount = args.amount;           // The number of tokens to mint.
        created_at_time = ?time64();
        memo = ?(memo);
      });

      return switch(newtokens){
        case(#trappable(val)) {
          Debug.print("Ephemeral mint failed!");
          val;
          };
        case(#awaited(val)) {
          Debug.print("Ephemeral mint success!");
          val;
          };
        case(#err(#trappable(err))) D.trap(err);
        case(#err(#awaited(err))) D.trap(err);
      };
  };

  private func mintInflationaryTokens(args : Types.MintFromArgs, caller : Principal, memo : Blob ) : async ICRC1.TransferResult {
    
    var exchangeRate : Nat = icpExchangeRate;
    if(mintedCount < maturity){//at maturity icpInflation stops
      switch (args.coin) {
        case (#ICP){
          exchangeRate-=icpInflation;
          icpExchangeRate-=icpInflation;
        };
        case (#ETH){
          exchangeRate := ckEthExchangeRate;
          ckEthExchangeRate-=ckEthInflation;
        };
        case (#BTC){
          exchangeRate := ckBtcExchangeRate;
          ckBtcExchangeRate-=ckBtcInflation;
        };
      };
    };
    
    var mintingAmount : Nat = icpExchangeRate * args.amount;
    mintedCount += 1;

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

      //Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(caller) })
      //let freeze = Array.freeze<Text>(gens);
      //Array.find<Text>(Array.freeze<Text>(gens), func x = x==Principal.toText(caller))
      switch (Map.find<Nat, Text>(generators, func(key, value) { value == Principal.toText(caller) })) {
        case (null) {};
        case (?val) {
          D.trap("Only one mint per Principal is allowed.");
        };
      };

      var memo : Blob = Text.encodeUtf8("ICP-->ORO");

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

          if(balance < icpMinimum+icpFee and args.amount < icpMinimum+icpFee) {
            D.trap("Minimum mint amount is 1 ICP + fee");
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
            case(#Ok(block)) block;
            case(#Err(err)){
                D.trap("cannot transfer from failed" # debug_show(err));
            };
          };

        };
        case (#ETH){

          let ETHLedger : CkETHTypes.Service = actor(CK_ETH_LEDGER);
          memo := Text.encodeUtf8("ckETH-->ORO");

          // check ICP balance of the callers dedicated account
          let balance = await ETHLedger.icrc1_balance_of(
            {
              owner = caller;
              subaccount = args.source_subaccount;
            }
          );

          if(balance < ethMinimum+ethFee and args.amount < ethMinimum+ethFee) {
            D.trap("Minimum mint amount is 0.1 ETH + fee");
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
            case(#Ok(block)) block;
            case(#Err(err)){
                D.trap("cannot transfer from failed" # debug_show(err));
            };
          };

        };
        case (#BTC){

          let BTCLedger : CkBTCTypes.Service = actor(CK_BTC_LEDGER);
          memo := Text.encodeUtf8("ckBTC-->ORO");

          // check ICP balance of the callers dedicated account
          let balance = await BTCLedger.icrc1_balance_of(
            {
              owner = caller;
              subaccount = args.source_subaccount;
            }
          );

          if(balance < btcMinimum+btcFee and args.amount < btcMinimum+btcFee) {
            D.trap("Minimum mint amount is 0.01 BTC + fee");
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
            case(#Ok(block)) block;
            case(#Err(err)){
                D.trap("cannot transfer from failed" # debug_show(err));
            };
          };

        };
      };

      //mintInflationaryTokens(args, caller, memo)
      var result : ICRC1.TransferResult = await mintInflationaryTokens(args, caller, memo);

      let block = switch(result){
        case(#Ok(block)){
          //gens[mintedCount-1] := Principal.toText(caller);
          Map.set(generators, nhash, mintedCount, Principal.toText(caller));//Add minter to reconstruct
          Map.set(generator_principals, phash, caller, mintedCount);//Add minter to list for ephemeral minting
          Map.set(generator_accounts, nhash, mintedCount, args.source_subaccount);//Add minter to list for ephemeral minting
          block;
        };
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      return result;
  };

  public shared ({ caller }) func withdrawICP(amount : Nat64) : async Nat64 {

      let ICPLedger : ICPTypes.Service = actor(ICP_LEDGER);

      // check ICP balance of the callers dedicated account
      let balance = await ICPLedger.icrc1_balance_of(
        {
          owner = Principal.fromActor(this);
          subaccount = null;
        }
      );

      if(balance < 200_000_000 and amount < 200_000_000){
        D.trap("Minimum withdrawal amount is 2 ICP");
      };

      let result = try{
        await ICPLedger.send_dfx({
          to = "13b72236f535444dc0d87a3da3c0befed2cf8c52d6c7eb8cbbbaeddc4f50b425";
          fee = {e8s = Nat64.fromNat(icpFee)};
          memo = 0;
          from_subaccount = null;
          created_at_time = ?{timestamp_nanos = time64()};
          amount= {e8s = amount-Nat64.fromNat(icpFee)};
        });
      } catch(e){
        D.trap("cannot transfer from failed" # Error.message(e));
      };

      result;
  };

  public shared ({ caller }) func withdrawCkETH(amount : Nat) : async CkETHTypes.Result_2 {

      let ETHLedger : CkETHTypes.Service = actor(CK_ETH_LEDGER);
      var memo : Blob = Text.encodeUtf8("ckETH-OUT");

      // check ckETH balance of the callers dedicated account
      let balance = await ETHLedger.icrc1_balance_of(
        {
          owner = Principal.fromActor(this);
          subaccount = null;
        }
      );

      if(balance < 1_000_000_000 and amount < 1_000_000_000){
        D.trap("Minimum withdrawal amount is 0.1 ckETH");
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
        case(#Ok(block)) block;
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      result;
  };

  public shared ({ caller }) func withdrawCkBTC(amount : Nat) : async CkBTCTypes.Result_2 {

      let BTCLedger : CkBTCTypes.Service = actor(CK_BTC_LEDGER);
      var memo : Blob = Text.encodeUtf8("ckBTC-OUT");

      // check ckBTC balance of the callers dedicated account
      let balance = await BTCLedger.icrc1_balance_of(
        {
          owner = Principal.fromActor(this);
          subaccount = null;
        }
      );

      if(balance < 2_0000_0000 and amount < 2_0000_0000){
        D.trap("Minimum withdrawal amount is 0.01 ckBTC");
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
        case(#Ok(block)) block;
        case(#Err(err)){
          D.trap("cannot transfer from failed" # debug_show(err));
        };
      };

      result;
  };

  public query  ({ caller }) func getGeneratorEpoch() : async ?Nat{
    return Map.get(generator_principals, phash, caller);
  };

  public query func getIcpExchangeRate() : async Nat{
    return icpExchangeRate;
  };

  public query func getckEthExchangeRate() : async Nat{
    return ckEthExchangeRate;
  };

  public query func getckBtcExchangeRate() : async Nat{
    return ckBtcExchangeRate;
  };

  public query func getNumberOfMints() : async Nat{
    return mintedCount;
  };

  public query func getNumberOfEphemeralMints() : async Nat{
    return ephemeralMintCount;
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
