angular.module('mieszkalk', []).directive('numberinput', ->
	restrict: 'A'
	require: 'ngModel'
	link: (scope, element, attrs, ngModelController) ->
		ngModelController.$parsers.push((data) ->
			# convert data from view format to model format
			data.replace(',', ".") # converted
		)
)

strToList = (value) ->
	raw = value.split(',')
	ret = []
	for p in raw
		p = p.trim()
		if p != ''
			ret.push(p)
	ret


mieszkalk = ($scope) ->
	$scope.model =
		people:
			names: []
			disabled:
				'Krzesłomir': ['Wungiel']
				'Wierzchosława': ['Herbata']
		expenses:
			names: []
			values:
				'Prąd': 15.67,
				'Wungiel': 20,
				'Herbata': 84
			dont_split:
				'Wungiel': true
		calculated: {}
		total: {}
		unaccounted: 10
		strings:
			people: 'Pankracy, Krzesłomir, Wierzchosława'
			expenses: 'Czynsz, Prąd, Wungiel, Herbata, Wywóz śmieci'

	$scope.$watch('model.strings.people', (newValue, oldValue)->
		raw = strToList(newValue)
		$scope.model.people.names = raw
		ret = {}
		for person in raw
			ret[person] = if person of $scope.model.people.disabled then $scope.model.people.disabled[person] else []
		$scope.model.people.disabled = ret
	)
	$scope.$watch('model.strings.expenses', (newValue, oldValue)->
		$scope.model.expenses.names = strToList(newValue)
		expenses_values = {}
		for expense in $scope.model.expenses.names
			expenses_values[expense] = if expense of $scope.model.expenses.values then $scope.model.expenses.values[expense] else 0
		$scope.model.expenses.values = expenses_values
	)
	$scope.$watch('model.expenses', ((newValue, oldValue) -> recalculate()), true)
	$scope.$watch('model.people', ((newValue, oldValue) -> recalculate()), true)

	$scope.toggleExpense = (person, expense) ->
		if expense in $scope.model.people.disabled[person]
			$scope.model.people.disabled[person].splice($scope.model.people.disabled[person].indexOf(expense), 1)
		else
			$scope.model.people.disabled[person].push(expense)
	$scope.toggleSplit = (expense) ->
		$scope.model.expenses.dont_split[expense] = !$scope.model.expenses.dont_split[expense]

	recalculate = ->
		# Check how many people have different expenses disabled
		expenses_values = {}
		true_total = 0
		for expense, value of $scope.model.expenses.values
			value = parseFloat(value, 10)
			if isNaN(value)
				value = 0
			true_total += value
			# Populate dont_split, by the way
			if not $scope.model.expenses.dont_split[expense]?
				$scope.model.expenses.dont_split[expense] = false
			divider = $scope.model.people.names.length
			if not $scope.model.expenses.dont_split[expense]
				for person in $scope.model.people.names
					if expense in $scope.model.people.disabled[person]
						divider--
			expenses_values[expense] = value / divider
		ret = {}
		ret_total =
			__all__: 0
		for person in $scope.model.people.names
			retp = {}
			total = 0
			for expense in $scope.model.expenses.names
				retp[expense] = if expense in $scope.model.people.disabled[person] then 0 else expenses_values[expense]
				total += retp[expense]
			ret_total[person] = total
			ret[person] = retp
			ret_total['__all__'] += total
		$scope.model.calculated = ret
		$scope.model.total = ret_total
		$scope.model.unaccounted = true_total - ret_total['__all__']
		# Save to localStorage
		saveToLS()

	saveToLS = ->
		@localStorage['people'] = JSON.stringify($scope.model.people)
		@localStorage['expenses'] = JSON.stringify($scope.model.expenses)
	loadFromLS = ->
		if 'people' of @localStorage
			people = JSON.parse(@localStorage['people'])
			if 'names' of people
				$scope.model.people.names = people.names
			if 'disabled' of people
				$scope.model.people.disabled = people.disabled
			$scope.model.strings.people = people.names.join(', ')
		if 'expenses' of @localStorage
			expenses = JSON.parse(@localStorage['expenses'])
			if 'names' of expenses
				$scope.model.expenses.names = expenses.names
			if 'values' of expenses
				# Convert to float first!
				for expense, value of expenses.values
					value = parseFloat(value, 10)
					if isNaN(value)
						value = 0
					expenses.values[expense] = value
				$scope.model.expenses.values = expenses.values
			if 'dont_split' of expenses
				$scope.model.expenses.dont_split = expenses.dont_split
			$scope.model.strings.expenses = expenses.names.join(', ')
	loadFromLS()
