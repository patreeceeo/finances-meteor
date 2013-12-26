
_.extend Template['scenario-detail'],
  scenario: ->
    currentScenario
  showHelp: ->
    Session.get 'showHelp'
  events:
    'click [data-help]': ->
      Session.set 'showHelp', not Session.get('showHelp')
