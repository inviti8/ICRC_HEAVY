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
    account_id=$(icx principal-convert --to-hex $(icx principal-convert --to-hex $(dfx identity get-principal) 2>&1  | cut -d ' ' -f 2); echo $(printf '%x\n' $(echo $account_id | wc -c | xargs -I{} expr {} / 2))$(echo $account_id | xargs printf "%-62s\n" | tr ' ' 0)
    echo $account_id 
    dfx identity use ident-1
    echo "dfx ledger transfer ${account_id} --amount 1000 --memo ${i}"
    dfx ledger transfer $account_id --amount 1000 --memo $i
done