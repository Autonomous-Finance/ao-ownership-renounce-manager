# AO Ownership Renounce Manager

An AO process to be used as a tool for **easily verifiable, trustable ownership renouncement** over AO processes.

Any Owner of an AO process can use the _Ownership Renounce Manager_ in order to renounce ownership over their owned process by following the suggested pattern.

The official instance of this process (the AO singleton) is currently
`wA4k2u-NqBfBsjbQWq9cWnv2Cn98hB-osDXx9AfPaMA`
 
## Background - AO Process Ownership

Process ownership on AO is based on the global process variable `Owner`. We also have an `ao.env.Process.Owner` value, but that one is currently immutable.

The `Owner` can be set to any AO entity ID (another process ID, some wallet ID)

The account stored in `Owner` is the only one who can send `Eval` messages, i.e. perform updates on the process: set global variable values, add new Handlers, remove existing handlers, ...

There are 2 ways in which `Owner` can change: 
- an Eval message with `Owner = ...` that sets the new value
- a handler that performs `Owner = ...` under certain conditions

### AO vs. EVM

We cannot "read" public state of an AO process because there is no such thing as **public state of an AO process**. 
For an EVM smart contract though, it is possible for anyone to **read the public state of a contract**. The network guarantees that the reading is accurate (truthful).

An EVM smart contract typically manages ownership via a public state variable `owner` and a function modifier `onlyOwner` that checks `msg.sender == owner` on certain gated functions.
The public can easily check for the current owner through Etherscan.

On AO we can check for a process Owner in 2 ways:
- an Eval message with `Data = "Owner"`  - this can be sent only by the owner himself and will evaluate the code `"Owner"`, which will give the value of the global process variable `Owner`
- a handler that matches `Action = "Get-Owner"` that returns a message with `Data = Owner` - this would be called by anyone (public getter - style)


### The attack vector on AO

If a public handler `"Get-Owner"` exists, it may return whatever it wants. Not necessarily the current `Owner`. So the owner of a process may renounce Ownership, have a dedicate handler that restores their ownership, and also have the `"Get-Owner"` handler permanently return `''`.

As a regular user, your only way to check what a given handler does, and therefore to be sure that `"Get-Owner"` tells the truth, is to reconstruct the complete history of `"Eval"`s that were run on a process.

## Ownership Renounce Manager

The Ownership Renounce Manager can **perform the ownership renouncement for any process *XYZ***.

The renouncement happens via a **specific exchange of messages**. After that exchange, *XYZ* is left not only in a state with `Owner == ''`, but also a state in which it is not possible to run any code via any other handler, that would leave the process in a state where `Owner ~= ''`

This makes sure that, even though there is no `Owner` at the moment, there is also no tricky handler that, via hidden execution paths, may later again assign someone as the owner.

### Trust Assumption 

The _Ownership Renounce Manager_ is designed as a **trusted singleton process** on AO.

Its logic is simple and needs to be immutable. By inspecting the first 3 Eval messages in the [message history](https://www.ao.link/#/entity/8kSVzbM6H25JeX3NuHp15qI_MAGq4vSka4Aer5ocYxE?tab=source-code) of the _Ownership Renounce Manager_, you can be certain of itsfelf being with ownerhip-renounced and therefore immutable.

Look for an Eval message in the *Manager's* history with "Owner = ''" in order to verify this fact.

As a consequence, _Ownership Renounce Manager_ can act as a UNIVERSALLY TRUSTED process on AO.

## Usage

If you own a process and you want to renounce ownership using the _Ownership Renounce Manager_, you need to:

1. set that process' `Owner` to _Ownerhip Renounce Manager_
2. immediately send a message with `{"Action" = "MakeRenounce"}` to the _Ownership Renounce Manager_
   

```lua
Owner = OWNERSHIP_RENOUNCE_MANAGER_PROCESS_ID
ao.send({Target = OWNERSHIP_RENOUNCE_MANAGER_PROCESS_ID, Action = "MakeRenounce"})
```

For the purpose of this scenario, we call your process the _Renouncer_.

After performing these steps and after the subsequent message handling has concluded, the _Renounce Ownership Manager_ can reliably **verify/certify** that _Renouncer_ is no longer owned by anyone. This is achieved by

```lua
ao.send({Target = OWNERSHIP_RENOUNCE_MANAGER_ID, Action = "IsRenounced", ProcessID = RENOUNCER_ID})
```

Alternatively, the renouncement can be inferred by querying the gateway for an event-message sent by the _Ownership Renounce Manager_ to itself.

```lua
ao.send({
  Target = ao.id, -- _Ownership Renounce Manager_
  Event = "RenounceOwnership",
  ProcessID = msg.From -- process that has renounced ownership via the _Ownership Renounce Manager_
})
```

## How It Works

Upon receiving a `"MakeRenounce"` message, _Ownerhip Renounce Manager_ sends an `Eval` to install a new handler on _Renouncer_, which revokes ownership when triggered.

The installed handler is also marked with a **nonce** that is partly random, partly specific to the current time. Therefore the nonce **cannot be known beforehand** by _Renouncer_.

Additionally to ownership renouncement, the installed handler **sends a message with the nonce back** to the _Ownerhip Renounce Manager_, thereby proving that it has executed the handler installed specifically for this purpose.

Upon receiving the confirmation of the Handler being added, the _Ownership Renounce Manager_ proceeds to triggering that handler, thereby effectively renouncing its own ownership over _Renouncer_.

