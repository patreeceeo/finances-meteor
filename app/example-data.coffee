AccountCollection = new Meteor.Collection null,
  transform: (doc) ->
    new finances.Account doc
ItemCollection = new Meteor.Collection null,
  transform: (doc) ->
    new finances.Item doc
PaymentCollection = new Meteor.Collection null,
  transform: (doc) ->
    new finances.Payment doc

AccountCollection.insert example for example in [
  { name: 'dude' }
  { name: 'walter' }
]
ItemCollection.insert example for example in [
  { name: 'ball', amount: 6 }
  { name: 'whiterussian', amount: 6 }
]
PaymentCollection.insert example for example in [
  {
    fromAccount:
      AccountCollection.findOne name: 'dude'
    item:
      ItemCollection.findOne name: 'ball'
  }
  {
    fromAccount:
      AccountCollection.findOne name: 'walter'
    item:
      ItemCollection.findOne name: 'whiterussian'
  }
]


exports = this
_.extend exports,
  AccountCollection: AccountCollection
  ItemCollection: ItemCollection
  PaymentCollection: PaymentCollection

