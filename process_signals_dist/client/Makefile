all:
	erl -pa ebin -sname ctrl

test:
	rm -rf ebin/* src/*~ test_ebin/* test_src/*~;
	erlc -o ebin src/*.erl;
	erlc -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin -s test_adder_eunit test -sname w1
