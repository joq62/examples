%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_client).
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(SERVER_NODE,'server@asus').
-define(SERVICE,adder).
%% External exports

-export([start/0,ctrl/0,ctrl_start/0,
	t1_test/0,t2_test/0,t3_test/0,t4_test/0,t5_test/0]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
start()->
    ctrl_start(),
    io:format("t1 = ~p~n",[{?MODULE,?LINE,rpc:call(node(),
					      test_client,t1_test,[],5000)}]),
    io:format("t2 = ~p~n",[{?MODULE,?LINE,rpc:call(node(),
					      test_client,t2_test,[],5000)}]),
    io:format("t3 = ~p~n",[{?MODULE,?LINE,rpc:call(node(),
					      test_client,t3_test,[],5000)}]),
    io:format("t4 = ~p~n",[{?MODULE,?LINE,rpc:call(node(),
					      test_client,t4_test,[],5000)}]),
    io:format("t5 = ~p~n",[{?MODULE,?LINE,rpc:call(node(),
					      test_client,t5_test,[],5000)}]),

    do_kill(),
    ok.

%%%%%%%%%%%%%%%%%% Change here   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
t1_test()->
    R= get_worker(?SERVICE),
    case R  of
	{ok,Pid}->
	    42=l_rpc(Pid,1,reply,add,[20,22]),
	    stopped_normal=l_rpc(Pid,2,reply,stop),
	    ok;
	{error,Err} ->
	    {error,Err}
    end.

t2_test()->
   case get_worker(?SERVICE) of
	{ok,Pid}->
	   X=l_rpc(Pid,glurk),
	   {P,{error,unmatched_signal,glurk}}=X,
	   stopped_normal=l_rpc(P,2,reply,stop),
	   ok;
	{error,Err} ->
	    {error,Err}
    end.


t3_test()->
    case get_worker(?SERVICE) of
	{ok,Pid}->
	    4.0=l_rpc(Pid,1,reply,divi,[20,5]),
	    stopped_normal=l_rpc(Pid,2,reply,stop),  
	    ok;
	{error,Err} ->
	    {error,Err}
    end.

t4_test()->
    case get_worker(?SERVICE) of
	{ok,Pid}->
	    {badrpc,_Err}=l_rpc(Pid,1,reply,divi,[20,0]),
	    stopped_normal=l_rpc(Pid,2,reply,stop), 
	    ok;
	{error,Err} ->
	    {error,Err}
    end.

t5_test()->
    case get_worker(?SERVICE) of
	{ok,Pid}->
	    l_rpc(Pid,1,reply,divi2,[20,0]),
	    stopped_normal=l_rpc(Pid,2,reply,stop),
	    ok;
	{error,Err} ->
	    {error,Err}
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctrl_start()->
    Pid_ctrl=spawn(test_client,ctrl,[]),
    true=register(ctrl,Pid_ctrl).

ctrl()->
    {Status,Pid_service}=rpc:call(?SERVER_NODE,?SERVICE,start,[[]]),
    io:format(" ~p~n",[{?MODULE,?LINE,Status,Pid_service}]),
    erlang:monitor(process,Pid_service),
    ctrl_loop(Pid_service).
ctrl_loop(Pid_service)->
    receive
	{From,{allocate,Service}}->
	    {allocate_ack,[{Pid,Node}]}=l_rpc(Pid_service,1,reply,allocate,[1]),
	    _Ref=erlang:monitor(process,Pid),
	    From!{ctrl,{pid,Pid}},
	    ctrl_loop(Pid_service);
	{_From,stop}->
	    Pid_service!{self(),{1,noreply,stop}},
	    io:format(" ~p~n",[{?MODULE,?LINE,stop}]);
	 {'DOWN',_Ref,process,_Pid,normal}->
	    ctrl_loop(Pid_service);
	 {'DOWN',_Ref,process,_Pid,Err}->
	    io:format("Down process ~p~n",[{?MODULE,?LINE,Err}]),
	    ctrl_loop(Pid_service);
	Err ->
	    io:format("Err ~p~n",[{?MODULE,?LINE,Err}]),
	    ctrl_loop(Pid_service)
    end.
    
get_worker(Service)->	    
    ctrl!{self(),{allocate,Service}},
    Res=receive
	    {ctrl,{pid,Pid}}->
		{ok,Pid}
	after 5000 ->
		{error,timeout}
	end,
    Res.
    

stop_test()->
    do_kill(),
    ok.
do_kill()->
    ctrl!{self(),stop},
    timer:sleep(1000),
    init:stop().


l_rpc(Pid,Msg)->
    Pid!{self(),Msg},	   
    receive
	R->
	    R
    end.
    
l_rpc(Pid,Id,Reply,Msg)->
    Pid!{self(),{Id,Reply,Msg}},
    R=case Reply of
	  reply->
	      receive
		  {Pid,{Id,Result}}->
		      Result;
		  Err->
		      Err
	      end;
	  noreply->
	      ok
      end,
    R.


l_rpc(Pid,Id,Reply,F,Args)->
    Pid!{self(),{Id,Reply,F,Args}},
    R=case Reply of
	  reply->
	      receive
		  {Pid,{Id,Result}}->
		      Result;
		  Err->
		    Err 
	      end;
	  noreply->
	      ok
      end,
    R.
