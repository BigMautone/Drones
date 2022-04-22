block faultSys "Gestisce le possibili fault dei droni. Possono esserci fault alla sensoristica, alle componenti di manovra e/o alle componenti di comunicazione"

/*
In caso di:
- Fault della sensoristica: il modulo di collisionAvoidance non riuscirà a calcolare la traiettoria esatta al fine di non far collidere 2 droni
- Fault del modulo di comunicazione: Le informazioni riguardanti l'algoritmo di pathfinding non vengono condivise con il drone soggetto al fault e con i suoi vicini
- Fault di manovra: Il drone smette di funzionare

*/

	parameter Real T = 5.0 "Tempo di aggiornamento probabilità fault";	

	//Matrice che identifica la probabilità di transizione
	//Riga 1 = funzionante; Riga 2 = sensoristica; Riga 3 = manovra; Riga 4 = comunicazione
	parameter Real transMatrix[4,4] = [0.8, 0.1, 0, 0.1;
										0.6, 0.4, 0, 0;
										0, 0, 1, 0;
										0.7, 0, 0, 0.3];

	//probabilità calcolatà randomicamente
	Real prob;
	
	//stato del drone. Viene restituito al drone stesso per valutare la sua situazione
	OutputInt state[K.N];
	
algorithm
	//inizializzo lo stato 
	when initial() then
		state := fill(1,K.N);
		prob := 0;

	elsewhen sample(0,T) then
		for i in 1:K.N loop	
			prob := myrandom();
			//print("Drone "+ String(i) +": " + String(state[i])+", " + String(prob) + "\n");
			state[i] := nextState(pre(state[i]), transMatrix, prob);
			if(state[i] == 3) then 
				print(String(i) + " sfondato;\n");
			end if;
		end for;
	end when;

end faultSys;

function nextState "calcola il nuovo stato del drone. Nel caso in cui il valore del random sia maggiore della probabilità in posizione 1 dello stato di partenza, allora aggiorniamo val finchè val >= z"
	
	InputInt state;
	InputReal matr[:,:];
	InputReal rand;	

	OutputInt newState;

	protected 
		Integer i;
		Real val;
algorithm
	i := 1;
	val := matr[state,i];
	while(i < size(matr, 1) and (rand > val)) loop
		i := i+1;		
		val := val + matr[state,i];
	end while; 

	newState := i;
	

end nextState;



 
