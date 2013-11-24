_.extend Template['home'],
  events:
    'click [data-start-button]': ->
      Router.go 'account-form', scenario: currentScenario._id
