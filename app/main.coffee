


Meteor.startup ->

Router.map ->
  @route 'home',
    path: '/'
  @route 'account-form',
    path: '/accounts'
    data:
      stepNumber: 1
      page: 'account-form'
      nextPage: 'item-form'

  @route 'item-form',
    path: '/items'
    data:
      stepNumber: 2
      page: 'item-form'

  @route 'item-detail-form',
    path: '/item/:name'
    data: ->
      itemName: @params.name
      stepNumber: 2
      page: 'item-detail-form'
      upPage: 'item-form'

