
log =
  write: ->
    console.debug.apply console, arguments

#
# dinner:
#   sugardaddy: Fred
#   moochers: Dafny Shaggy Scooby
# hotel:
#   sugermomma: Thelma
#   moochers: Fred Shaggy Scooby

if not _?
  _ = Package?.underscore._

class Base
  constructor: (doc) ->
    _.extend this, doc
  toJSON: ->
    _(this).omit 'scenario'

class Item extends Base
  # constructor: (doc) ->
  #   _.extend this, doc
    # @name = @attributes.name
    # @amount = @attributes.amount
    # @scenario = @attributes.scenario
    # _id = @attributes._id
    # unless @scenario.byId[_id]? and _id?
    #   @scenario.items.push this
    #   @scenario.byId[_id] = this
  toJSON: ->
    name: @name
    amount: @amount
  clone: (name) ->
    @scenario.createItem name: name, amount: @amount

class Account extends Base
  # constructor: (doc) ->
  #   _.extend this, doc
    # @name = @attributes.name
    # @usesItems = @attributes.usesItems or []
    # @sendsPayments = []
    # @receivesPayments = []
    # @scenario = @attributes.scenario
    # _id = @attributes._id
    # unless @scenario.byId[_id]? and _id?
    #   @scenario.accounts.push this
    #   @scenario.byId[_id] = this
  pays: (item, percent = 100) ->
    @scenario.createPayment
      item: item.toJSON()
      percent: percent
      fromAccount: @toJSON()
  uses: (item) ->
    @scenario.createUsage
      item: item.toJSON()
      fromAccount: @toJSON()
  paysAndUses: (item, percent = 100) ->
    @pays(item, percent)
    @uses(item)
  crunch: ->
    total = 0
    for p in @scenario.findPayments(fromAccount: { name: @name }, settled: false)
      log.write "include in total #{p.toString()}"
      total += p.amount
    total: total
  toJSON: ->
    name: @name

class Payment extends Base
  constructor: (doc) ->
    super

    @amount = doc.amount or doc.item.amount
    @settled = if doc.settled? then doc.settled else true
  isInternal: ->
    @fromAccount? and @toAccount?
  toString: ->
    """#{
    if @settled
      ''
    else
      'unsettled '
    }payment from #{
      @fromAccount.name
    } to #{
      @toAccount?.name
    } for #{
      @item?.name
    } ($#{
      @amount
    })"""
  toJSON: ->
    _id: @_id
    amount: @amount
    settled: @settled
    fromAccount: @fromAccount
    toAccount: @toAccount

class Usage extends Base

class Scenario
  constructor: (opts) ->
    _.extend this, opts
  createAccount: (doc) ->
  createItem: (doc) ->
  createPayment: (doc) ->
  createUsage: (doc) ->
  findAccounts: (sel) ->
  findItems: (sel) ->
  findPayments: (sel) ->
  findUsages: (sel) ->
  findAccount: (sel) ->
  findItem: (sel) ->
  findPayment: (sel) ->
  findUsage: (sel) ->
  findUsers: (item) ->
    usages = @findUsages item: item
    @findAccount(usage.fromAccount) for usage in usages
      
  deletePayment: (sel) ->
    # log.write "delete #{deleteMe.toString()}"
    # deleteFrom = (propName) ->
    #   in: (object) ->
    #     object[propName] =
    #     _(object[propName]).reject (o) ->
    #       o is deleteMe

    # deleteFrom('sendsPayments').in(deleteMe.fromAccount)
    # deleteFrom('receivesPayments').in(deleteMe.toAccount)

    # TODO: should a payment actually be made settled after
    #       it's deleted?
    # deleteMe.settled = true
  createOrIncreasePayment: (attributes) ->
    payment = @findPayment 
      fromAccount: attributes.fromAccount
      toAccount: attributes.toAccount

    if payment
      log.write "increase #{payment.toString()} by $#{attributes.amount}"
      payment.amount += attributes.amount
      @savePayment payment
      payment
    else
      @createPayment attributes
  createInternalPayments: ->
    for item in @findItems({})
      for p in @findPayments({item: item.toJSON()}) when p.settled
        users = @findUsers(item.toJSON())
        for user in users when user.name isnt p.fromAccount.name
          @createOrIncreasePayment
            amount: item.amount / users.length
            toAccount: p.fromAccount
            fromAccount: user.toJSON()
            settled: false
    undefined
  simplifyPayments: ->
    # Simplify the payment graph as much as
    # possible without changing the ultimate
    # flow of $$$.
    #
    # Pseudo-code for a general solution:
    # The => symbol represents a payment between two accounts
    # Arithmetic operations with payments are performed with payment amounts
    # Assignment operations create payments if none existed previously
    #
    #
    # For each A1 => A2
    #   If A2 => A3
    #     If A1 => A2 > A2 => A3
    #       (A1 => A3) += (A1 => A2) - (A2 => A3)
    #       (A1 => A2) -= (A1 => A3)
    #       (A2 => A3) = 0
    #     Else If A1 => A2 < A2 => A3
    #       (A1 => A3) += (A2 => A3) - (A1 => A2)
    #       (A2 => A3) -= (A1 => A3)
    #       (A1 => A2) = 0
    #     Else If A1 => A2 is A2 => A3
    #       (A1 => A3) = (A1 => A2)
    #       (A1 => A2) = (A2 => A3) = 0

    # Implemenation:

    payments = _(@findPayments({settled: false})).sortBy('amount')
    for p in payments
      for p2 in payments when p.toAccount.name is p2.fromAccount.name and
          not (p.settled or p2.settled)
        log.write """#{
          p.fromAccount.name
        } owes $#{
          p.amount
        } to #{
          p.toAccount.name
        } and #{
          p2.fromAccount.name
        } owes $#{
          p2.amount
        } to #{
          p2.toAccount.name
        }"""

        if p.amount is p2.amount
          if p.fromAccount.name isnt p2.toAccount.name
            log.write "redirect #{p.toString()} to #{p2.toAccount.name}"
            p.toAccount = p2.toAccount
            @savePayment p.toJSON()
          else
            log.write "delete #{p.toString()}"
            @deletePayment(p.toJSON())
            p.settled = true
          log.write "delete #{p2.toString()}"
          @deletePayment(p2.toJSON())
          p2.settled = true
        else
          minflow = Math.min(p.amount, p2.amount)

          if p.fromAccount.name isnt p2.toAccount.name
            payments.push newp = @createOrIncreasePayment
              fromAccount: p.fromAccount
              toAccount: p2.toAccount
              amount: minflow
              settled: false
          
          if p.amount > p2.amount
            larger = p
            smaller = p2
          else
            larger = p2
            smaller = p

          if larger.amount > minflow
            log.write "decrease #{larger.toString()} by $#{minflow}"
            larger.amount -= minflow
            @savePayment larger.toJSON()
          else
            log.write "delete #{larger.toString()}"
            @deletePayment(larger.toJSON())
            larger.settled = true
          log.write "delete #{smaller.toString()}"
          @deletePayment(smaller.toJSON())
          smaller.settled = true

    undefined


@finances =
  Item: Item
  Account: Account
  Payment: Payment
  Scenario: Scenario
  Usage: Usage
  getPRNG: (seed) ->
    (min, max) ->
      x = Math.sin(seed++) * 10000
      r = x - Math.floor(x)
      Math.round r * (max - min) + min
  testScenario: (seed, scenario) ->
    random = @getPRNG(seed)
    totalPayments = 0

    nUsers = random(2, 10)
    nPayers = random(2, 10)

    nAccounts = do ->
      min = Math.max(nUsers, nPayers)
      random(min, nUsers + nPayers)
    nItems = random(Math.max(nUsers, nPayers), nAccounts * 3)

    accounts =
      for i in [1..nAccounts]
        scenario.createAccount name: "account #{i}"
    items =
      for i in [1..nItems]
        scenario.createItem
          name: "item #{i}"
          amount: random(2, 100)

    payments = []
    for index, item of items
      payments.push accounts[index % nPayers].pays item
      accounts[accounts.length - 1 - index % nUsers].uses item
      totalPayments += item.amount
    

    totalPayments: totalPayments
    accounts: accounts
    items: items
    payments: payments
