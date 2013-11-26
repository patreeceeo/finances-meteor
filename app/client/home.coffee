_.extend Template['home'],
  events:
    'click [data-start-button]': ->
      Router.go 'scenario-form'
