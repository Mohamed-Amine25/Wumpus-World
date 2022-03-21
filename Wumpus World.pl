:- dynamic ([visited/1,
             breeze/1,
             stench/1,
             glitter/1,
             moved/2,
             wumpus_location/1,
             pit_location/1,
             gold_location/1,
             agent_location/1,
             timer/1,
             score/1,
             wumpus_final_location/1]).




adjacent([X,Y],L) :- Xr is X+1, L=[Xr,Y].
adjacent([X,Y],L) :- Xl is X-1, L=[Xl,Y].
adjacent([X,Y],L) :- Yt is Y+1, L=[X,Yt].
adjacent([X,Y],L) :- Yb is Y-1, L=[X,Yb].

%----------------------------------------------------------------------------



border([X,Y]) :- X<1; X>4; Y<1; Y>4.

%----------------------------------------------------------------------------


makestatement([X,Y]) :-
            forall((pit_location(PL),adjacent([X,Y],PL)), (format('there is a breeze in ~p~n',[[X,Y]]),assert(breeze([X,Y])))),
            forall((wumpus_location(L),adjacent([X,Y],L)), (format('there is a stench in ~p~n',[[X,Y]]),assert(stench([X,Y])))),
            forall((gold_location(G),([X,Y] == G)),(assert(glitter([X,Y])),score(S), N is S + 500 , format('I have found GOLD, Score is now ~p~n',[N]), retractall(score(_)),retractall(glitter(_)),retractall(gold_location(_))., assert(score(N)))).

%----------------------------------------------------------------------------



pit([X,Y]) :- forall(adjacent([X,Y],L), (breeze(L);border(L))).
pit([X,Y]) :- adjacent([X,Y],L), visited(L), breeze(L), forall(adjacent(L,L2),(L2 == [X,Y] ; psafe(L2) ; border(L2))).

%----------------------------------------------------------------------------


wumpus([X,Y]) :- forall(adjacent([X,Y],L), (stench(L);border(L))), retractall(wumpus_final_location(_)),assert(wumpus_final_location([X,Y])).
wumpus([X,Y]) :- adjacent([X,Y],L), visited(L), stench(L), forall(adjacent(L,L2),(L2 == [X,Y];wsafe(L2); border(L2))),
             retractall(wumpus_final_location(_)),assert(wumpus_final_location([X,Y])).
gold([X,Y]) :- glitter([X,Y]).

psafe([X,Y]) :- adjacent([X,Y],L), visited(L), \+ breeze(L).
wsafe([X,Y]) :- adjacent([X,Y], L), visited(L), \+ stench(L).

fail_agent([X,Y]) :- pit([X,Y]); wumpus([X,Y]).

maybe([X,Y]) :- \+ visited([X,Y]), \+ fail_agent([X,Y]), ( adjacent([X,Y],L), ( breeze(L);stench(L))).

safe([X,Y]) :- visited([X,Y]).

safe([X,Y]) :- psafe([X,Y]), wsafe([X,Y]).

good([X,Y]) :- safe([X,Y]), \+visited([X,Y]).

existgood(A) :- visited(V), adjacent(V,A), good(A), \+ visited(A), \+ border(A).

existmaybe(A) :- visited(V), adjacent(V,A), maybe(A), \+ visited(A), \+ border(A).

failure(X):- wumpus_location(W), pit_location(P), (X=W;X=P), format('Eaten!') ,halt.
exist(X):- existgood(X);existmaybe(X).
start:-
    init,
    agent_location(AL),
    \+acte(AL),
    wumpus_final_location(Z),
    (Z=[-1,-1])->  format('The agent failed to find the Wumpus~nFAILED !~n'); (  wumpus_final_location(Z), format('The wumpus is located in ~p! I am shooting my bullet!~n',[Z])),
    score(S),
    timer(T),
    format('Score: ~p~n',[S]),
    format('timer: ~p~n',[T]),
    format('WON!').

acte(X):-
    retractall(agent_location(_)),
    assert(agent_location(X)),
    update_score(-1),
    update_timer(1),
    format('I am in ~p~n',[X]),
    %failure(X),
    assert(visited(X)),
    makestatement(X),
    exist(L),
    get_next(N,L,X),
    wumpus_final_location(Z),
    Z = [-1,-1],
    acte(N).

get_next([X,Y],[X1,Y1],[X2,Y2]):-
    (adjacent([X1,Y1],[X2,Y2])) ->  ([X,Y] = [X1,Y1]);(adjacent([X1,Y1],L),visited(L)) ->([X,Y]=L).
update_score(X):-
    score(S),
    Z is S+X,
    retractall(score(_)),
    assert(score(Z)).
update_timer(X):-
    timer(S),
    Z is S+X,
    retractall(timer(_)),
    assert(timer(Z)).

init:-
    retractall(timer(_)),
    assert(timer(0)),
    retractall(score(_)),
    assert(score(30)),
    retractall(gold_location(_)),
    assert(gold_location([3,3])),
    retractall(wumpus_location(_)),
    assert(wumpus_location([4,4])),
    retractall(pit_location(_)),
    assert(pit_location([1,4])),
    assert(pit_location([3,1])),
    retractall(agent_location(_)),
    assert(agent_location([1,1])),
    retractall(wumpus_final_location(_)),
    assert(wumpus_final_location([-1,-1])).