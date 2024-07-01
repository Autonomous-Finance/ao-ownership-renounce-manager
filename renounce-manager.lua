IsRenounced = IsRenounced or {} -- map process id to boolean

Version = '0.1'

--[[  _OwnershipRenounceManager_ should, by convention, be a simple trusted singleton process on AO.

  PREMISE

  Its logic is simple and needs to be immutable.
  It is deployed with an immediate ownership renouncement (Eval message with "Owner = ''")
    => checking its first message after deployment verifies immutability
      => _OwnershipRenounceManager_ is UNIVERSALLY TRUSTED on AO

  FUNCTION

  Any process owner that wants to perform a verifiable ownership renouncement on their process
  would first set that process' `Owner` to _OwnerhipRenounceManager_ (this),
  then send a message ('Action' = 'MakeRenounce') to it.

  For the purpose of this scenario, we call the other process _Renouncer_.

  _OwnerhipRenounceManager_ would send an `Eval` to install a new handler on _Renouncer_,
  which would revoke ownership when triggered.
  The installed handler is also marked with a nonce that is partly random, partly specific
  to the current time.

  => The nonce cannot be known beforehand by _Renouncer_.

  Additionally to ownership renouncement, the installed handler would SEND A MESSAGE WITH THE NONCE
  back to the _OwnerhipRenounceManager_, thereby proving that has executed the handler installed
  specifically for this purpose.
]]


-- Trustable way to publicly verify that a particular process has had its ownership renounced
-- via this _RenounceManager_
Handlers.add(
  'isRenounced',
  Handlers.utils.hasMatchingTag('Action', 'IsRenounced'),
  function(msg)
    ao.send({
      Target = msg.From,
      IsRenounced = IsRenounced[msg.Tags.ProcessID]
    })
  end
)

Nonces = Nonces or {} -- map process id to nonce

local createEvalText = function(nonce)
  return [[
    Handlers.add(
      'renounceOwnership',
      Handlers.utils.hasMatchingTag('Action', 'RenounceOwnership'),
      function(msg)
        Owner = ''
        ao.send({
          Target = ']] .. ao.id .. [[',
          Action = 'Renounced',
          Nonce = ']] .. nonce .. [['
        })
        Handlers.prepend(
          'ensureRenounced',
          function() return 'continue' end,
          function()
            assert(Owner == '', 'This contract is supposed to have its ownership renounced')
          end
        )
      end
    )

    ao.send({
      Target = ']] .. ao.id .. [[',
      Action = 'Ack',
      Nonce = ']] .. nonce .. [['
    })

  ]]
end

-- Sent by any _Renouncer_
Handlers.add(
  'makeRenounce',
  Handlers.utils.hasMatchingTag('Action', 'MakeRenounce'),
  function(msg)
    local targetProcess = msg.From
    -- this process is the owner of the target process right now
    local nonce = tostring(msg.Timestamp) .. '-' .. tostring(math.random(1, 1000000))
    Nonces[msg.From] = nonce
    ao.send({
      Target = targetProcess,
      Action = 'Eval',
      Data = createEvalText(nonce)
    })
  end
)

-- _Renouncer_ acknowledges that it has installed the renouncement Handler
Handlers.add(
  'ack',
  Handlers.utils.hasMatchingTag('Action', 'Ack'),
  function(msg)
    if msg.Tags.Nonce == Nonces[msg.From] then
      ao.send({ Target = msg.From, Action = 'RenounceOwnership' })
    end
  end
)

-- Persist Renouncement
Handlers.add(
  'renounced',
  Handlers.utils.hasMatchingTag('Action', 'Renounced'),
  function(msg)
    if msg.Tags.Nonce == Nonces[msg.From] then
      IsRenounced[msg.From] = true
      ao.send({
        Target = ao.id,
        Event = 'RenounceOwnership',
        ProcessID = msg.From
      })
    end
  end
)
