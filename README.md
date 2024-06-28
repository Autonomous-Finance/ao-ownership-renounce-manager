# AO Ownership Renounce Manager

An AO process to be used as a tool for **easily verifiable, trustable ownership renouncement** over AO processes.

Any Owner of an AO process can use the _Ownership Renounce Manager_ in order to renounce ownership over their owned process by following the suggested pattern.

The official instance of this process (the AO singleton) is currently
`XDY51mdAWjuEYEWaBNVR6p4mNGLHMDVvo5vPJOqEszg`
 
## Assumptions

The _Ownership Renounce Manager_ is designed as a trusted singleton process on AO.

Its logic is simple and needs to be immutable. By inspecting the first 3 Eval messages in the [message history](https://www.ao.link/#/entity/XDY51mdAWjuEYEWaBNVR6p4mNGLHMDVvo5vPJOqEszg?tab=source-code) of the _Ownership Renounce Manager_, you can be certain of itsfelf being with ownerhip-renounced and therefore immutable.

Look for an Eval message with "Owner = ''" in order to verify.

As a consequence, _Ownership Renounce Manager_ can act as a UNIVERSALLY TRUSTED process on AO.

## Usage

If you own a process and you want to renounce ownership using the _Ownership Renounce Manager_, you need to:

1. set that process' `Owner` to _Ownerhip Renounce Manager_
2. immediately send a message with `{"Action" = "MakeRenounce"}` to the _Ownership Renounce Manager_

For the purpose of this scenario, we call your process the _Renouncer_.

After performing these steps and after the subsequent message handling has concluded, the _Renounce Ownership Manager_ can reliably **verify/certify** that _Renouncer_ is no longer owned by anyone. This is achieved by

```lua
ao.send({Target = OWNERSHIP_RENOUNCE_MANAGER_ID, Action = "IsRenounced", ProcessID = RENOUNCER_ID})
```

## How It Works

Upon receiving a `"MakeRenounce"` message, _Ownerhip Renounce Manager_ sends an `Eval` to install a new handler on _Renouncer_, which revokes ownership when triggered.

The installed handler is also marked with a nonce that is partly random, partly specific to the current time. Therefore the nonce **cannot be known beforehand** by _Renouncer_.

Additionally to ownership renouncement, the installed handler would **send a message with the nonce back** to the _Ownerhip Renounce Manager_, thereby proving that it has executed the handler installed specifically for this purpose.

Upon receiving the confirmation of the Handler being added, the _Ownership Renounce Manager_ proceeds to triggering that handler, thereby effectively renouncing its own ownership over _Renouncer_.

