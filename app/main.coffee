

# Meteor.startup ->
#   do prepareTestData

Router.map ->
  @route 'home',
    path: '/'
  @route 'account-form',
    path: ':scenario/accounts'
    data: ->
      scenarioId: @params.scenario
      page: 'account-form'
      nextPage: 'item-form'

  @route 'item-form',
    path: ':scenario/items'
    data: ->
      scenarioId: @params.scenario
      page: 'item-form'
      nextPage: 'results'

  @route 'item-detail-form',
    path: ':scenario/item/:id'
    data: ->
      scenarioId: @params.scenario
      itemId: @params.id
      page: 'item-detail-form'
      upPage: 'item-form'
      nextPage: 'results'

  @route 'results',
    path: ':scenario/results'


