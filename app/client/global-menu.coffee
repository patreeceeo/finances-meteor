
_.extend Template['global-menu'], do ->

  nextButtonDisabled = ->
    not Router.getData().nextPage? or
    switch Router.getData().page
      when 'item-form'
        ItemCollection.find({}).count() < 2
      when 'account-form'
        AccountCollection.find({}).count() < 2
  upButtonDisabled = ->
    not Router.getData().upPage?
  nextButtonDisabled: nextButtonDisabled
  upButtonDisabled: upButtonDisabled
  stepNumber: ->
    Router.getData().stepNumber
  events: do ->
    'click [data-next-button]': ->
      if not nextButtonDisabled()
        Router.go Router.getData().nextPage
    'click [data-up-button]': ->
      if not upButtonDisabled()
        Router.go Router.getData().upPage
