# Exit immediately if a command exits with a non-zero status, and print each command.
set -ex

dfx identity use ident-1

ADMIN_PRINCIPAL=$(dfx identity get-principal)
TOKEN=$(dfx canister id token)

max=900000
user='user'

for i in `seq 2 $max`
do
    u=$user$i
    dfx identity new $u --storage-mode=plaintext || true
    dfx identity use $u
    account_id=$(dfx ledger account-id --of-principal $(dfx identity get-principal))
    echo $account_id 
    dfx identity use ident-1
    echo "dfx ledger transfer ${account_id} --amount 1000 --memo ${i}"
    dfx ledger transfer $account_id --amount 1000 --memo $i
    dfx identity use $u
    dfx canister call token icrc2_approve '
    record {
        amount = 200_010_000;
        spender = record {
        owner = principal "'${TOKEN}'";
        };
    }
    '
    dfx canister call icrc1_ledger_canister icrc2_allowance "
    record { 
        account = record{owner = principal \"${u}\";}; 
        spender = record{owner = principal \"${TOKEN}\";} 
    }
    "
    dfx canister call token mintFromToken '
    record {
        coin = variant { ICP };
        source_subaccount + null;
        target = null;
        amount = 200_000_000;
    }
    '
done