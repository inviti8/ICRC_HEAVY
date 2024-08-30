dfx identity new minter --storage-mode plaintext
dfx identity use minter
export MINTER=$(dfx identity get-principal)

dfx identity new admin --storage-mode plaintext
dfx identity use admin
export ADMIN=$(dfx identity get-principal)

#Deploy the Oro canister
dfx deploy token --argument "(opt record {icrc1 = opt record {
  name = opt \"Oro Token\";
  symbol = opt \"ORO\";
  logo = opt \"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMSIgaGVpZ2h0PSIxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9InJlZCIvPjwvc3ZnPg==\";
  decimals = 16;
  fee = opt variant { Fixed = 10000};
  minting_account = opt record{
    owner = principal \"${MINTER}\";
    subaccount = null;
  };
  max_supply = null;
  min_burn_amount = opt 10000;
  max_memo = opt 64;
  advanced_settings = null;
  metadata = null;
  fee_collector = null;
  transaction_window = null;
  permitted_drift = null;
  max_accounts = opt 100000000;
  settle_to_accounts = opt 99999000;
}; 
icrc2 = opt record{
  max_approvals_per_account = opt 10000;
  max_allowance = opt variant { TotalSupply = null};
  fee = opt variant { ICRC1 = null};
  advanced_settings = null;
  max_approvals = opt 10000000;
  settle_to_approvals = opt 9990000;
}; 
icrc3 = opt record {
  maxActiveRecords = 3000;
  settleToRecords = 2000;
  maxRecordsInArchiveInstance = 100000000;
  maxArchivePages = 62500;
  archiveIndexType = variant {Stable = null};
  maxRecordsToArchive = 8000;
  archiveCycles = 20_000_000_000_000;
  supportedBlocks = vec {};
  archiveControllers = null;
};
icrc4 = opt record {
  max_balances = opt 200;
  max_transfers = opt 200;
  fee = opt variant { ICRC1 = null};
};})" --mode reinstall

ORO_CANISTER=$(dfx canister id token)

icp_max=2
eth_max=3
btc_max=4
user='user'

# -------------------------------------------------------------ICP Test-------------------------------------------------------------------
# Deploy ICP ledger canister 
# initialy admin have 1000 ICP tokens
dfx deploy icp_ledger --argument "(
  variant {
    Init = record {
      decimals = opt 8;
      token_symbol = \"ICP\";
      transfer_fee = 10_000 ;
      metadata = vec {};
      minting_account = record {
        owner = principal \"${MINTER}\";
        subaccount = null;
      };
      initial_balances = vec { record { record { owner = principal \"${ADMIN}\"; }; 100_000_000_000; }; };
      maximum_number_of_accounts = null;
      accounts_overflow_trim_quantity = null;
      fee_collector_account = null;
      archive_options = record {
        num_blocks_to_archive = 100 : nat64;
        max_transactions_per_response = null;
        trigger_threshold = 100 : nat64;
        max_message_size_bytes = null;
        cycles_for_archive_creation = null;
        node_max_memory_size_bytes = null;
        controller_id = principal \"${ADMIN}\";
      };
      max_memo_length = null;
      token_name = \"ICP\";
      feature_flags = null;
    }
  },
)"

for i in `seq 2 $max`
do
    #create new user 
    u=$user$i
    dfx identity new $u --storage-mode plaintext
    dfx identity use $u
    pid=$(dfx identity get-principal)
    
    #transfer 10 ICP + fee from admin to new user
    dfx canister call --identity admin icp_ledger icrc1_transfer "(record { 
        to = record { 
            owner = principal \"${pid}\";
            subaccount = null;                                                                    
        };                  
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 1_000_010_000;
    })"

    #give allowance(10 ICP) to token canister for icp transfer
    dfx canister call --identity $u icp_ledger icrc2_approve '
    record {
        amount = 1_000_000_000;
        spender = record {
        owner = principal "'${ORO_CANISTER}'";
        };
    }
    '
    #check allowance value
    dfx canister call --identity $u icp_ledger icrc2_allowance '
    record { 
        account = record{owner = principal "'${pid}'";}; 
        spender = record{owner = principal "'${ORO_CANISTER}'";} 
    }
    '
    #mint oro token by ICP
    dfx canister call --identity $u token mintFromToken '
    record {
        coin = variant { ICP };
        source_subaccount = null;
        target = null;
        amount = 1_000_000_000;
    }
    '
done

# --------------------------------------------------------------ETH Test-----------------------------------------------------------------
# Deploy ETH ledger canister 
# initialy admin have 18 ETH tokens
dfx deploy eth_ledger --argument "(
  variant {
    Init = record {
      decimals = opt 18;
      token_symbol = \"ckETH\";
      transfer_fee = 2_000_000_000_000 ;
      metadata = vec {};
      minting_account = record {
        owner = principal \"${MINTER}\";
        subaccount = null;
      };
      initial_balances = vec { record { record { owner = principal \"${ADMIN}\"; }; 18_000_000_000_000_000_000; }; };
      maximum_number_of_accounts = null;
      accounts_overflow_trim_quantity = null;
      fee_collector_account = null;
      archive_options = record {
        num_blocks_to_archive = 100 : nat64;
        max_transactions_per_response = null;
        trigger_threshold = 100 : nat64;
        max_message_size_bytes = null;
        cycles_for_archive_creation = null;
        node_max_memory_size_bytes = null;
        controller_id = principal \"${ADMIN}\";
      };
      max_memo_length = null;
      token_name = \"ckETH\";
      feature_flags = null;
    }
  },
)"

for i in `seq $((icp_max+1)) $eth_max`
do
    #create new user 
    u=$user$i
    dfx identity new $u --storage-mode plaintext
    dfx identity use $u
    pid=$(dfx identity get-principal)
    
    #transfer 0.01 ETH + fee from admin to new user
    dfx canister call --identity admin eth_ledger icrc1_transfer "(record { 
        to = record { 
            owner = principal \"${pid}\";
            subaccount = null;                                                                    
        };                  
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 10_002_000_000_000_000;
    })"

    #give allowance(0.01 ETH) to token canister for eth transfer
    dfx canister call --identity $u eth_ledger icrc2_approve '
    record {
        amount = 10_000_000_000_000_000;
        spender = record {
        owner = principal "'${ORO_CANISTER}'";
        };
    }
    '
    #check allowance value
    dfx canister call --identity $u eth_ledger icrc2_allowance '
    record { 
        account = record{owner = principal "'${pid}'";}; 
        spender = record{owner = principal "'${ORO_CANISTER}'";} 
    }
    '
    #mint oro token by ETH
    dfx canister call --identity $u token mintFromToken '
    record {
        coin = variant { ETH };
        source_subaccount = null;
        target = null;
        amount = 10_000_000_000_000_000;
    }
    '
done

# --------------------------------------------------------------BTC Test-----------------------------------------------------------------
# Deploy BTC ledger canister 
# initialy admin have 10 BTC tokens
dfx deploy btc_ledger --argument "(
  variant {
    Init = record {
      decimals = opt 8;
      token_symbol = \"ckBTC\";
      transfer_fee = 10 ;
      metadata = vec {};
      minting_account = record {
        owner = principal \"${MINTER}\";
        subaccount = null;
      };
      initial_balances = vec { record { record { owner = principal \"${ADMIN}\"; }; 1_000_000_000; }; };
      maximum_number_of_accounts = null;
      accounts_overflow_trim_quantity = null;
      fee_collector_account = null;
      archive_options = record {
        num_blocks_to_archive = 100 : nat64;
        max_transactions_per_response = null;
        trigger_threshold = 100 : nat64;
        max_message_size_bytes = null;
        cycles_for_archive_creation = null;
        node_max_memory_size_bytes = null;
        controller_id = principal \"${ADMIN}\";
      };
      max_memo_length = null;
      token_name = \"ckBTC\";
      feature_flags = null;
    }
  },
)"

for i in `seq $((eth_max+1)) $btc_max`
do
    #create new user 
    u=$user$i
    dfx identity new $u --storage-mode plaintext
    dfx identity use $u
    pid=$(dfx identity get-principal)
    
    #transfer 0.001 BTC + fee from admin to new user
    dfx canister call --identity admin btc_ledger icrc1_transfer "(record { 
        to = record { 
            owner = principal \"${pid}\";
            subaccount = null;                                                                    
        };                  
        fee = null;
        memo = null;
        from_subaccount = null;
        created_at_time = null;
        amount = 100_010;
    })"

    #give allowance(0.001 BTC) to token canister for btc transfer
    dfx canister call --identity $u btc_ledger icrc2_approve '
    record {
        amount = 100_000;
        spender = record {
        owner = principal "'${ORO_CANISTER}'";
        };
    }
    '
    #check allowance value
    dfx canister call --identity $u btc_ledger icrc2_allowance '
    record { 
        account = record{owner = principal "'${pid}'";}; 
        spender = record{owner = principal "'${ORO_CANISTER}'";} 
    }
    '
    #mint Oro token by BTC
    dfx canister call --identity $u token mintFromToken '
    record {
        coin = variant { BTC };
        source_subaccount = null;
        target = null;
        amount = 100_000;
    }
    '
done