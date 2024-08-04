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
    principal=$(dfx identity get-principal)
    account_id=$(icx principal-convert --to-hex $principal)
    dfx ledger transfer $account_id --amount 1000 --memo 1
done
