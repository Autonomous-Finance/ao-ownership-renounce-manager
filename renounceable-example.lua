AoOwnershipRenounceManager = '...' -- the AO renouncer process

Handlers.add(
  'triggerRenounce',
  Handlers.utils.hasMatchingTag("Action", "TriggerRenounce"),
  function(msg)
    Owner = AoOwnershipRenounceManager
    msg.send({ Target = Owner, Action = 'MakeRenounce' })
  end
)
