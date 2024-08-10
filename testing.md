## Setting up local NNS test environment:

Install the dfx-nns extension for dfx, documented [here.](https://github.com/dfinity/sdk/blob/master/docs/cli-reference/dfx-nns.mdx)

The local nns can only be connected on port 8080.  
Edit dfx.json in your token repo to reflect this by adding the following data to the bottom of the json:
```json
"networks": {
    "local": {
      "bind": "127.0.0.1:8080",
      "replica": {
        "subnet_type": "system"
      },
      "type": "ephemeral"
    }
  },
```
## Install the extension

First start dfx in the repo:
```
dfx start --clean --background
```
Next install the nns extension:
```
dfx extension install nns
```
Then install the nns dependencies:
```
dfx nns install
```
Once done, you should see a list of all the canisters that were installed:
![c29e6787210e68c05410b6d81e6da6aa.png](:/d9c2a6151ad040f7a36e522380b67857)

Now we need to import the nns canister to dfx.json:
```
dfx nns import
```
 We now have a local instance of the nns running
 ***
 
Next we must install the test identity, by creating a pem file.  
Create a new file called 'ident-1.pem', save in the repo. Then paste the text below into the file and save.

```
-----BEGIN EC PRIVATE KEY-----
MHQCAQEEICJxApEbuZznKFpV+VKACRK30i6+7u5Z13/DOl18cIC+oAcGBSuBBAAK
oUQDQgAEPas6Iag4TUx+Uop+3NhE6s3FlayFtbwdhRVjvOar0kPTfE/N8N6btRnd
74ly5xXEBNSXiENyxhEuzOZrIWMCNQ==
-----END EC PRIVATE KEY-----
```

Install the identity from the pem file with:

```
dfx identity import ident-1 ident-1.pem
dfx identity use ident-1
```

* * *

With the nns dependencies, and the test identity created, verify with:

```
dfx identity whoami
>>ident-1
```

* * *

This identity comes with fake icp, verify this with:

```
dfx ledger balance
>> 1000000000.00000000
```

* * *
We can then deploy the test token, using ident-1:

```
dfx deploy token
```
Take note of the canister id after deploy, we will need this later.
***
After the token is deployed, we need to make the token canister admin, be the canister itself:
```
dfx canister call token admin_update_icrc1
```

Several prompts will follow:

```
? Do you want to enter a new vector element (y/n) >
>>y
```

Then select 'MintingAccount' from the variant list:

```
...
?Select a variant > (Page 2/2)
> MintingAccount
 FeeCollector
 MaxAccounts
...
```

Then we are asked for a Principal, which should be set the the canister id, which was printed to the terminal when the token canister was initially deployed.

```
Enter a principal > <$TOKEN CANISTER ID>
Enter optional field subaccount > no

?Do you want to enter a new vector element? (y/n) > no
```

Then send the message to confirm the vector element change:

```
Do you want to sent this message? [y/N]
>>y
{vec { true}}
```
The canister is now ready for testing
* * *
To run the tests, while cd'd into the token repo, give the test script permissions:
```
chmod +x ./runners/test_lifecycle.sh
```

run the life cycle tests:
```
./runners/test_lifecycle.sh
```
 
 This script will create a bunch of identities and transfer tokens to them, until requirements of the mintFromToken requirements are achieved.
