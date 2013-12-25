#
# dinner:
#   sugardaddy: Fred
#   moochers: Dafny Shaggy Scooby
# hotel:
#   sugermomma: Thelma
#   moochers: Fred Shaggy Scooby

log =
  write: ->
    console.debug.apply console, arguments

union = (arr1, arr2) ->
  unless _.isArray(arr1) and _.isArray(arr2)
    debugger
  _.union arr1, arr2
difference = (arr1, arr2) ->
  unless _.isArray(arr1) and _.isArray(arr2)
    debugger
  _.difference arr1, arr2
  

@finances ?= 
  concatNames: (list, separator = '/') ->
    (o.name for o in list).join(separator)
  round: (val) ->
    Math.round(val * 100) / 100
  sum: (documents) ->
    retval = 0
    for doc in documents
      retval += doc.amount
    retval
  buildArithmaticExpression: (addends = [], subtrahends = []) ->
    addendCount = {}
    subtrahendCount = {}
    for addend in addends
      addendCount[addend.name] ?= 0
      addendCount[addend.name] += 1
    for subtrahend in subtrahends
      subtrahendCount[subtrahend.name] ?= 0
      subtrahendCount[subtrahend.name] += 1
    addendExpression = (
      for own name, count of addendCount
        "#{name}"
    ).join '+'
    subtrahendExpression = (
      for own name, count of subtrahendCount
        "#{name}"
    ).join '-'
    "#{
      if addendExpression.length
        addendExpression
      else
        ''
    }#{
      if subtrahendExpression.length
        "-#{subtrahendExpression}"
      else
        ''
    }"


pstr = (doc) ->
  (new finances.Payment doc).toString()
istr = (doc) ->
  (new finances.Item doc).toString()
astr = (doc) ->
  (new finances.Account doc).toString()
ustr = (doc) ->
  (new finances.Usage doc).toString()

if not _?
  _ = Package?.underscore._

class finances.Base
  constructor: (doc) ->
    _.extend this, doc 
  findOne: (Collection, selector, options) ->
    extendedSelector = _.extend _(selector or {}).clone(),
      scenario: @scenario or @_id
    Collection.findOne extendedSelector, options
  find: (Collection, selector = {}, options = {}) ->
    extendedSelector = _.extend _(selector).clone(),
      scenario: @scenario or @_id
    Collection.find(extendedSelector, options)
  _scenario: (selector = @scenario, options = {}) ->
    @findOne ScenarioCollection, selector, options
  _account: (selector = @account, options = {}) ->
    @findOne AccountCollection, selector, options
  _accounts: (selector, options = {}) ->
    @find AccountCollection, selector, options
  _item: (selector = @item, options = {}) ->
    @findOne ItemCollection, selector, options
  _items: (selector, options = {}) ->
    @find ItemCollection, selector, options
  _payment: (selector = @payments, options = {}) ->
    @findOne PaymentCollection, selector, options
  _payments: (selector, options = {}) ->
    @find PaymentCollection, selector, options
  _usage: (selector = @usage, options = {}) ->
    @findOne UsageCollection, selector, options
  _usages: (selector, options = {}) ->
    @find UsageCollection, selector, options
  add: (Collection, document) ->
    extendedDocument = _.extend _(document).clone(), 
      scenario: @scenario or @_id
    _id = Collection.insert extendedDocument
    extendedDocument._id = _id
    @findOne(Collection, _id) 
  update: (Collection, document, _id = document._id) ->
    throw new Error("Trying to update '#{@constructor.name}' without `_id`") unless _id?
    Collection.update _id, $set: _(document).omit '_id'
  remove: (Collection, _id) ->
    Collection.remove(_id)
  _fromAccount: ->
    @_account @fromAccount
  _toAccount: ->
    @_account @toAccount

class finances.Scenario extends finances.Base
  addAccount: (document) ->
    new finances.Account @add AccountCollection, document
  addItem: (document) ->
    document.amount = finances.round parseInt document.amount
    new finances.Item @add ItemCollection, document
  addPayment: (document) ->
    new finances.Payment @add PaymentCollection, document
  addUsage: (document) ->
    new finances.Usage @add UsageCollection, document
  updateAccount: (document) ->
    @update AccountCollection, document
  updateItem: (document) ->
    @update ItemCollection, document
  updatePayment: (document) ->
    @update PaymentCollection, document
  updateUsage: (document) ->
    @update UsageCollection, document
  removeAccount: (_id) ->
    @remove AccountCollection, _id
  removeItem: (_id) ->
    @remove ItemCollection, _id
  removePayment: (_id) ->
    @remove PaymentCollection, _id
  removeUsage: (_id) ->
    @remove UsageCollection, _id 
  addOrIncreasePayment: (attributes) ->
    payment = @_payment 
      fromAccount: attributes.fromAccount
      toAccount: attributes.toAccount
      obviated: null

    # TODO: maybe make oppositePayment an optional param?
    oppositePayment = @_payment
      fromAccount: attributes.toAccount
      toAccount: attributes.fromAccount
      obviated: null

    if oppositePayment?
      if oppositePayment.amount > attributes.amount
        if payment?
          debugger
        payment = oppositePayment
        attributes = _(attributes).extend
          amount: -attributes.amount
          addItems: attributes.minusItems
          minusItems: attributes.addItems
      else
        # the opposite payment is annihilated by the new payment
        @removePayment oppositePayment
        attributes = _(attributes).extend
          amount: attributes.amount - oppositePayment.amount
          addItems: difference attributes.addItems, oppositePayment.addItems
          minusItems: union attributes.minusItems, oppositePayment.minusItems

    if payment?
      log.write "combine payment of $#{
        attributes.amount
      }#{
        if attributes.addItems?.length and attributes.minusItems?.length
          " for #{
            finances.buildArithmaticExpression (@_item(item) for item in attributes.addItems), (@_item(item) for item in attributes.minusItems)
          }"
        else
          ""
      } with #{
        pstr payment
      }"

      if attributes.amount?
        payment.amount += attributes.amount
      if attributes.addItems?
        payment.addItems = union payment.addItems, attributes.addItems
      if attributes.minusItems?
        payment.minusItems = union payment.minusItems, attributes.minusItems

      # Normalize negative payments
      if payment.amount <= 0
        debugger
        # TODO: if its possible to get here, also need
        #       to swap addItems and minusItems
        payment.amount = -payment.amount
        payment.toAccount = payment.fromAccount
        payment.fromAccount = payment.toAccount

      @updatePayment payment
      payment
    else if attributes.amount > 0
      log.write "add #{pstr(attributes)}"
      @addPayment attributes
    
  addInternalPayments: ->
    console.log 'addInternalPayments',@_id
    @_items().forEach (item) =>
      item = new finances.Item item
      payments = @_payments(addItems: item._id, settled: true).fetch()
      # itemAmount = finances.sum payments
      for payment in payments
        @_usages(item: item._id).forEach (usage) =>
          if usage.fromAccount isnt payment.fromAccount
            @addOrIncreasePayment
              amount: payment.amount / (item.valuate() / usage.amount)
              addItems: [item._id]
              minusItems: []
              toAccount: payment.fromAccount
              fromAccount: usage.fromAccount
              settled: false
      undefined
  simplifyPayments: ->
    console.log('simplifyPayments', @_id)
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

    @_payments(settled: false, {sort: ['amount', 'asc']}).forEach (p) =>
      
      @_payments(settled: false, fromAccount: p.toAccount).forEach (p2) =>
        return if p.obviated or p2.obviated
        log.write """#{
          @_account(p.fromAccount).name
        } owes $#{
          p.amount
        } to #{
          @_account(p.toAccount).name
        } and #{
          @_account(p2.fromAccount).name
        } owes $#{
          p2.amount
        } to #{
          @_account(p2.toAccount).name
        }"""

        if p.amount is p2.amount
          if p.fromAccount isnt p2.toAccount
            log.write "redirect #{pstr p} to #{@_account(p2.toAccount).name}"
            @addOrIncreasePayment
              fromAccount: p.fromAccount
              toAccount: p2.toAccount
              addItems: []
              minusItems: []
              amount: p.amount
              settled: false
          log.write "delete 1st equal edge: #{pstr p}"
          p.obviated = true
          @updatePayment p
          log.write "delete 2nd equal edge: #{pstr p2}"
          p2.obviated = true
          @updatePayment p2
        else
          if p.amount > p2.amount
            larger = p
            smaller = p2
          else
            larger = p2
            smaller = p

          minflow = smaller.amount

          if p.fromAccount isnt p2.toAccount
            @addOrIncreasePayment
              fromAccount: p.fromAccount
              addItems: []
              minusItems: []
              toAccount: p2.toAccount
              amount: minflow
              settled: false
          
          log.write "decrease larger #{pstr larger} by $#{minflow}"
          larger.amount -= minflow
          larger.minusItems = union larger.minusItems, smaller.addItems
          larger.addItems = union larger.addItems, smaller.minusItems
          @updatePayment larger
          log.write "delete smaller #{pstr smaller}"
          smaller.obviated = true
          @updatePayment smaller

    @_payments(obviated: true).forEach (p) =>
      @removePayment p._id

    undefined

class finances.Item extends finances.Base
  clone: (name) ->
    @add ItemCollection, name: name, amount: @amount
  toString: ->
    "#{@name} ($#{@amount})"
  valuate: ->
    finances.sum @_payments(addItems: @_id, settled: true).fetch()


class finances.Account extends finances.Base
  addPayment: (document) ->
    new finances.Payment @add PaymentCollection, document
  addUsage: (document) ->
    new finances.Usage @add UsageCollection, document
  pays: (item, amount = item.amount) ->
    log.write "#{@toString()} pays $#{amount or item.amount} for #{istr(item)}"
    @addPayment
      addItems: [item._id]
      minusItems: []
      fromAccount: @_id
      settled: true
      amount: amount
  uses: (item, amount = item.amount) ->
    log.write "#{@toString()} uses $#{amount} of #{istr(item)}"
    @addUsage
      item: item._id
      fromAccount: @_id
      amount: amount
  paysAndUses: (item, amount) ->
    @pays(item, amount)
    @uses(item, amount)
  # TODO: deprecate
  crunch: ->
    total = 0
    @_payments(fromAccount: @_id, settled: false).forEach (p) ->
      log.write "include in total #{pstr(p)}"
      total += p.amount
    total: total
  balance: ->
    balance = 0
    for payment in @_payments(fromAccount: @_id).fetch()
      balance -= payment.amount
    for payment in @_payments(toAccount: @_id).fetch()
      balance += payment.amount
    balance
  toString: ->
    @name
  
Payment =
class finances.Payment extends finances.Base
  vivifyAssociates: ->
    @fromAccount = @_account @fromAccount
    @toAccount = @_account @toAccount
    @addItems = @fetchItems @addItems
    @minusItems = @fetchItems @minusItems
    this
  addItem: (document) ->
    @amount += finances.round document.amount
    @addItems.push document._id
  fetchItems: (items = []) ->
    for item in items
      @_item item
  toString: ->
    """
    payment of $#{@amount} from #{
      @_fromAccount().name
    } to #{
      @_toAccount()?.name
    } for #{
      finances.buildArithmaticExpression(@fetchItems(@addItems), @fetchItems(@minusItems))
    }"""

class finances.Usage extends finances.Base
  vivifyAssociates: ->
    @fromAccount = @_account @fromAccount
    @item = @_item @item
    this

_.extend finances,
  getPRNG: (seed) ->
    (min, max) ->
      x = Math.sin(seed++) * 10000
      r = x - Math.floor(x)
      Math.round r * (max - min) + min
  randomZeroSumArray: (length, depth, seed) ->
    random = @getPRNG seed
    retval = (0 for i in [1..length])
    for i in [1..length]
      dig = random 0, depth
      retval[random 0, length - 1] -= dig
      retval[random 0, length - 1] += dig
    retval
  testScenario: (seed) ->
    console.count('testScenario')
    scenario = new finances.Scenario 
      name: "S#{seed}"
      _id: "#{seed}"
    random = @getPRNG(seed)
    totalPayments = 0

    nAccounts = random 2, 9
    nUsers = random 1, nAccounts
    nPayers = random 1, nAccounts

    nItems = random(nPayers * 0.1, nPayers * 1)

    console.debug 'nAccounts',nAccounts,'nItems',nItems

    accounts =
    for i in [1..nAccounts]
      scenario.addAccount 
        _id: "S#{seed}A#{i}"
        name: "A#{i}"

    items = 
    for i in [1..nItems]
      scenario.addItem
        _id: "S#{seed}I#{i}"
        name: "I#{i}"
        amount: random(1, 100/24) * 24

    for own index, item of items
      nPayersPerItem = Math.min Math.ceil(nAccounts/nItems), accounts.length - index
      zeroSumArray = @randomZeroSumArray nPayersPerItem, item.amount/ nPayersPerItem / 2, seed
      for groupIndex in [0...nPayersPerItem] 
        payerIndex = index % nPayers + groupIndex
        userIndex = accounts.length - 1 - (index + groupIndex) % nUsers
        accounts[payerIndex].pays item, item.amount / nPayersPerItem + zeroSumArray[groupIndex]
        accounts[userIndex].uses item, item.amount / nPayersPerItem

    scenario
