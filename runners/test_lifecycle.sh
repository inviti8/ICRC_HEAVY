# Exit immediately if a command exits with a non-zero status, and print each command.
set -ex

dfx identity use ident-1

ADMIN_PRINCIPAL=$(dfx identity get-principal)
TOKEN=$(dfx canister id token)

max=90
user='user'
marks=()  # Declare and initialize the array.

for i in {1..$max}  # Loop from 1 to max.
do
    mark=$(date +%s%N | cut -b1-$((i*3))))  # Generate a unique 3 character string based on current timestamp and iteration number.
    marks+=("$mark"))  # Add the generated string to the array.
done

for i in `seq 2 $max`
do
    u=$user$i
    dfx identity new $u --storage-mode=plaintext || true
    dfx identity use $u
    p=$(dfx identity get-principal)
    mark=$(marks[i])
    account_id=$(dfx ledger account-id --of-principal $p)
    echo "${u}"
    echo "Principal:"
    echo "${p}"
    echo "Account ID:"
    echo "${account_id}"
    echo "Mark:"
    echo "${mark}"
    dfx identity use ident-1
    echo "dfx ledger transfer ${account_id} --amount 1000 --memo ${i}"
    dfx ledger transfer $account_id --amount 1000 --memo $i
    dfx identity use $u
    dfx canister call --identity $u nns-ledger icrc2_approve '
    record {
        amount = 200_010_000;
        spender = record {
        owner = principal "'${TOKEN}'";
        };
    }
    '
    dfx canister call --identity $u nns-ledger icrc2_allowance '
    record { 
        account = record{owner = principal "'${p}'";}; 
        spender = record{owner = principal "'${TOKEN}'";} 
    }
    '
    dfx canister call --identity $u token mintFromToken '
    record {
        coin = variant { ICP };
        source_subaccount = null;
        target = null;
        mintMark = "'${mark}'";
        amount = 200_000_000;
    }
    '
done