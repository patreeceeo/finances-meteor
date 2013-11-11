scenario = new finances.Scenario


AccountCollection = new Meteor.Collection 'accounts',
  connection: null
  transform: (doc) ->
    scenario.createAccount doc
ItemCollection = new Meteor.Collection 'items',
  connection: null
  transform: (doc) ->
    scenario.createItem doc
PaymentCollection = new Meteor.Collection 'payments',
  connection: null
  transform: (doc) ->
    doc.fromAccount = AccountCollection.findOne doc.fromAccount
    doc.toAccount = AccountCollection.findOne doc.toAccount
    doc.item = ItemCollection.findOne doc.item
    scenario.createPayment doc

exports = this
_.extend exports,
  AccountCollection: AccountCollection
  ItemCollection: ItemCollection
  PaymentCollection: PaymentCollection
  currentScenario: scenario

