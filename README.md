# AO Ownership Renounce Manager

An AO process to be used by any Owner of an AO process in order to renounce ownership over their owned process.

The official instance of this process (the AO singleton) is currently
`XDY51mdAWjuEYEWaBNVR6p4mNGLHMDVvo5vPJOqEszg`
 
## Premise

The _Ownership Renounce Manager_ is designed as a simple trusted singleton process on AO.

Its logic is simple and needs to be immutable.

It is deployed with an immediate ownership renouncement (Eval message with "Owner = ''")
  => checking its first message after deployment verifies immutability
    => _Ownership Renounce Manager_ is UNIVERSALLY TRUSTED on AO

## Usage

Any process owner that wants to perform a verifiable ownership renouncement on their process would perform 2 steps:

1. set that process' `Owner` to _Ownerhip Renounce Manager_
2. immediately send a message with `{"Action" = "MakeRenounce"}` to the _Ownership Renounce Manager_

For the purpose of this scenario, we call the other process _Renouncer_.

After performing these steps and the subsequent message handling has concluded, the _Renounce Ownership Manager_ can reliably verify that _Renouncer_ is no longer owned by anyone. This is achieved by

```lua
ao.send({Target = OWNERSHIP_RENOUNCE_MANAGER_ID, Action = "IsRenounced", ProcessID = RENOUNCER_ID})
```

## How It Works

Upon receiving a `"MakeRenounce"` message, _Ownerhip Renounce Manager_ sends an `Eval` to install a new handler on _Renouncer_, which revokes ownership when triggered.

The installed handler is also marked with a nonce that is partly random, partly specific to the current time. Therefore the nonce **cannot be known beforehand** by _Renouncer_.

Additionally to ownership renouncement, the installed handler would **send a message with the nonce back** to the _Ownerhip Renounce Manager_, thereby proving that it has executed the handler installed specifically for this purpose.

Upon receiving the confirmation of the Handler being added, the _Ownership Renounce Manager_ proceeds to triggering that handler, thereby effectively renouncing its own ownership over _Renouncer_.

