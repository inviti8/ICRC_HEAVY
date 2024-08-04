# Exit immediately if a command exits with a non-zero status, and print each command.
set -ex

dfx identity use ident-1

ADMIN_PRINCIPAL=$(dfx identity get-principal)

#Deploy the canister
dfx deploy token --argument "(opt record {icrc1 = opt record {
  name = opt \"Oro\";
  symbol = opt \"ORO\";
  logo = opt \"data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMSIgaGVpZ2h0PSIxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9InJlZCIvPjwvc3ZnPg==\";
  decimals = 16;
  fee = opt variant { Fixed = 10000};
  minting_account = opt record{
    owner = principal \"$ADMIN_PRINCIPAL\";
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

max=900000
user='user'

for i in `seq 2 $max`
do
    dfx identity new "${user} ${i}" --storage-mode=plaintext || true
    dfx identity use "${user} ${i}"
    principal=$(dfx identity get-principal)
    account_id=$(icx principal-convert --to-hex $principal)
    dfx ledger transfer $account_id --amount 1000 --memo 1
done
