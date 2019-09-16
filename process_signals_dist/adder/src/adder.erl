%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : test application calc
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(adder).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("interfacesrc/brd_local.hrl").

%% --------------------------------------------------------------------
 
%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{}).

%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================


-export([start/1
	 ]).

%% ====================================================================
%% External functions
%% ====================================================================


%%-----------------------------------------------------------------------


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% ------------------------------------------------------------------
start(Args)->
    case whereis(?MODULE) of
	undefined->
	    io:format(" ~p~n",[{?MODULE,?LINE,undefined}]),
	    {ok,State}=init(Args),
	    Pid=spawn(fun()->server_loop(State) end ),
	    register(?MODULE,Pid),
	    Res={new,Pid};
	PidActive->
	    io:format(" ~p~n",[{?MODULE,?LINE,PidActive}]),
	    Res={active,PidActive}
    end,
    Res.

init(_Args)->
    {ok,#state{}}.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
server_loop(State)->
    receive
	{From,{MsgId,reply,allocate,[NumOfServices]}}->
	    ListOfWorker=start_workers(NumOfServices,[]),
	    From!{self(),{MsgId,{allocate_ack,ListOfWorker}}},
	    server_loop(State);
		% Control functions mandatory 
	{From,{MsgId,reply,stop}} ->
	    From!{self(),{MsgId,stopped_normal}};
	{_From,{_MsgId,noreply,stop}} ->
	    ok;
	{From,{MsgId,reply,is_alive}}->
	    From!{self(),MsgId,im_alive},
	    server_loop(State);
	{From,X}->
	    From!{self(),{error,unmatched_signal,X}},
	    NewState=State,
	    worker(NewState);
	Z->
	    io:format("should be error log ~p~n",[{?MODULE,?LINE,Z}]),
	    NewState=State,
	    worker(NewState)
    end.	    

start_workers(0,ListOFWorkers)->
    ListOFWorkers;
start_workers(N,Acc) ->
    Worker=init_worker([]),
    NewAcc=[Worker|Acc],
    start_workers(N-1,NewAcc).
%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------
init_worker(_Args)->
    State=#state{},
    Pid=spawn(fun()->worker(State) end ),
    {Pid,node()}.

worker(State)->    
    receive
	% Normal cases
	{From,{MsgId,reply,add,[A,B]}}->
	    R=rpc:call(node(),adder_lib,add,[A,B]),
	    From!{self(),{MsgId,R}},
	    NewState=State,
	    worker(NewState);
	{From,{MsgId,reply,add,[A,B],TimeOut}}->
	    R=rpc:call(node(),adder_lib,add,[A,B],TimeOut),
	    From!{self(),{MsgId,R}},
	    NewState=State,
	    worker(NewState);
	{From,{MsgId,reply,divi,[A,B]}}->
	    R=rpc:call(node(),adder_lib,divi,[A,B]),
	    From!{self(),{MsgId,R}},
	    NewState=State,
	    worker(NewState);
	{From,{MsgId,reply,divi,[A,B],TimeOut}}->
	    R=rpc:call(node(),adder_lib,divi,[A,B],TimeOut),
	    From!{self(),{MsgId,R}},
	    NewState=State,
	    worker(NewState);
	{From,{MsgId,reply,divi2,[A,B]}}->
	    R=A/B,
	    From!{self(),{MsgId,R}},
	    NewState=State,
	    worker(NewState);

	% Control functions mandatory 
	{From,{MsgId,reply,stop}} ->
	    From!{self(),{MsgId,stopped_normal}};
	{From,{MsgId,noreply,stop}} ->
	    From!{self(),{MsgId,stopped_normal}};
	{From,X}->
	    From!{self(),{error,unmatched_signal,X}},
	    NewState=State,
	    worker(NewState);
	Z->
	    io:format("should be error log ~p~n",[{?MODULE,?LINE,Z}]),
	    NewState=State,
	    worker(NewState)
    end.
    
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

