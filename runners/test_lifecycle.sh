# Exit immediately if a command exits with a non-zero status, and print each command.
set -ex

dfx identity use ident-1

ADMIN_PRINCIPAL=$(dfx identity get-principal)

max=900000
user='user'

for i in `seq 2 $max`
do
    dfx identity new $user$i --storage-mode=plaintext || true
    dfx identity use $user$i
    account_id=$(dfx ledger account-id --of-principal $(dfx identity get-principal))
    echo $account_id 
    dfx identity use ident-1
    echo "dfx ledger transfer ${account_id} --amount 1000 --memo ${i}"
    dfx ledger transfer $account_id --amount 1000 --memo $i
done