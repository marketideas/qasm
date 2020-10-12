*
* verify macro operand parsing handles quoted strings.
*

xx	mac
	asc ]1
	eom

	xx '"hello"'
	xx "'hello'"
	xx 'hello'
	xx "hello"
	xx 'abc',00
	xx ff
