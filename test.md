## Step 1 : Set up dfx.json

add below code in "canisters" section.
```
"icp_ledger": {
      "type": "custom",
      "candid": "https://raw.githubusercontent.com/dfinity/ic/8afebfa5ebdeccd50ec51f2233cd4887a6c9ee80/rs/rosetta-api/icrc1/ledger/ledger.did",
      "wasm": "https://download.dfinity.systems/ic/8afebfa5ebdeccd50ec51f2233cd4887a6c9ee80/canisters/ic-icrc1-ledger.wasm.gz",
      "specified_id": "ryjl3-tyaaa-aaaaa-aaaba-cai"
    },
    "eth_ledger": {
      "type": "custom",
      "candid": "https://raw.githubusercontent.com/dfinity/ic/8afebfa5ebdeccd50ec51f2233cd4887a6c9ee80/rs/rosetta-api/icrc1/ledger/ledger.did",
      "wasm": "https://download.dfinity.systems/ic/8afebfa5ebdeccd50ec51f2233cd4887a6c9ee80/canisters/ic-icrc1-ledger.wasm.gz",
      "specified_id": "ss2fx-dyaaa-aaaar-qacoq-cai"
    },
    "btc_ledger": {
      "type": "custom",
      "candid": "https://raw.githubusercontent.com/dfinity/ic/8afebfa5ebdeccd50ec51f2233cd4887a6c9ee80/rs/rosetta-api/icrc1/ledger/ledger.did",
      "wasm": "https://download.dfinity.systems/ic/8afebfa5ebdeccd50ec51f2233cd4887a6c9ee80/canisters/ic-icrc1-ledger.wasm.gz",
      "specified_id": "mxzaz-hqaaa-aaaar-qaada-cai"
    }
```

## Step 2 
In **mintInflationaryTokens** method of Token.mo set minter principal(used in test.sh) as 1st parameter of icrc1().mint_tokens method.
because only minting account of token can mint token and in this case token canister is not minting account.

## Step 3

Run command in terminal
```
./runners/test.sh
```