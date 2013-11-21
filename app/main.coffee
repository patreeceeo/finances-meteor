

# Meteor.startup ->
#   do prepareTestData

Router.map ->
  @route 'home',
    path: '/'
  @route 'account-form',
    path: '/accounts'
    data:
      page: 'account-form'
      nextPage: 'item-form'

  @route 'item-form',
    path: '/items'
    data:
      page: 'item-form'
      nextPage: 'results'

  @route 'item-detail-form',
    path: '/item/:name'
    data: ->
      itemName: @params.name
      page: 'item-detail-form'
      upPage: 'item-form'
      nextPage: 'results'

  @route 'results',
    path: '/results'


