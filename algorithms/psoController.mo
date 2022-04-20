block PSO "Modulo di controllo dell'algoritmo di pathfinding"
	
//tempo di aggiornamento del pso
parameter Real T = 0.5;

//tendenza dei droni di rimanere alla velocità del precedente timestamp
parameter Real w = 0.6;

//tendenza dei droni di esplorare l'area circostante
parameter Real c1 = 2;

//tendenza dei droni di convergere nel punto di arrivo 
parameter Real c2 = 2;

//Punti di arrivo dei droni
InputReal destX[K.N];
InputReal destY[K.N];
InputReal destZ[K.N];

//Posizione dei droni
InputReal x[K.N];
InputReal y[K.N];
InputReal z[K.N];

//Velocità dei droni
InputReal Vx[K.N];
InputReal Vy[K.N];
InputReal Vz[K.N];

//Stato dei droni
InputInt droneState[K.N];

//Droni vicini
InputBool neighbours[K.N,K.N];

//Posizione intrusi
InputReal intrX[K.nIntr];
InputReal intrY[K.nIntr];
InputReal intrZ[K.nIntr];

//intrusi vicini a droni
InputBool nearIntr[K.N, K.nIntr];

//global fitness e global position sono calcolate tramite il modulo di comunicazione


//Migliore posizione individuale
Real pBestPos[K.N,3];

//Migliore posizione globale.La gBest pos è unica, ma viene usata sotto forma di vettore per simulare la memorizzazione e la comunicazione della variabile per tutti i droni
Real gBestPos[K.N,3];

//migliore fitness value personale
Real pBestFit[K.N];

//Global fitnessValue. La gBest fit è unica, ma viene usata sotto forma di vettore per simulare la memorizzazione e la comunicazione della variabile per tutti i droni.
//La fitness value è un valore che identifica il livello di ottimizzazione del sistema simulato
Real globFitness[K.N];

//Variabile temporanea per il calcolo e confronto della fitness value
Real tmpFit[K.N];

//valori random per calcolare velocità
Real r1;
Real r2;

//Variabili temporanee per salvataggio dati risultanti dal modulo di comunicazione
Real tmpGPos[K.N,3];
Real tmpGFit[K.N];

//Permette di resettare i valori di fitness, così da aggiornare l'algoritmo
Real timer;

Real battery[K.N];

OutputReal velocityX[K.N];
OutputReal velocityY[K.N];
OutputReal velocityZ[K.N];

OutputReal batteryDischarge[K.N];

initial equation

	for i in 1:K.N loop
		pBestFit[i] = 100000;
		pBestPos[i] = {x[i],y[i],z[i]};

		globFitness[i] = 100000;
		gBestPos[i] = {x[i],y[i],z[i]};
	end for;

	velocityX = zeros(K.N);
	velocityY = zeros(K.N);
	velocityZ = zeros(K.N);
	batteryDischarge = zeros(K.N);

	r1 = 0;
	r2 = 0;
	timer = 0;
	
	tmpGPos = zeros(K.N,3);
	tmpGFit = zeros(K.N);
	tmpFit = zeros(K.N);

algorithm

when sample(0,T) then
	tmpFit := allFitness(x,y,z,destX,destY,destZ,intrX,intrY,intrZ, nearIntr);
	if(timer < 2) then
		timer := pre(timer) + 1;
	else 
		timer := 0;
		pBestFit := fill(100000.0, K.N);
		globFitness := fill(100000.0, K.N);
	end if;

	for i in 1:K.N loop

		//Confronto e setup Pbest. Posso calcolarlo qui poichè richiede solamente i dati del singolo drone.
		if(tmpFit[i] < pBestFit[i]) then
			pBestFit[i] := tmpFit[i];
			pBestPos[i] := {x[i],y[i],z[i]};
		end if;

		//Aggiornamento gBests da inviare al modulo di comunicazione
		if(tmpFit[i] < globFitness[i]) then
			globFitness[i] := tmpFit[i];
			gBestPos[i] := {x[i],y[i],z[i]};
		end if;
		
		r1 := myrandom();
		r2 := myrandom();
		
		velocityX[i] := ((w*Vx[i]) + (c1*r1* (pBestPos[i,1] - x[i])) + (c2*r2* (gBestPos[i,1] - x[i])));
		velocityY[i] := ((w*Vy[i]) + (c1*r1* (pBestPos[i,2] - y[i])) + (c2*r2* (gBestPos[i,2] - y[i])));
		velocityZ[i] := ((w*Vz[i]) + (c1*r1* (pBestPos[i,3] - z[i])) + (c2*r2* (gBestPos[i,3] - z[i])));

		//velocity cap
		(velocityX[i],velocityY[i],velocityZ[i]) := velocityCap(velocityX[i],velocityY[i],velocityZ[i], K.maxSpeed);
		//print("Velocità PSO: (" +String(velocityX[1]) + ", " +String(velocityY[1]) + ", " +String(velocityZ[1]) + ")\n");
	end for;

	(tmpGPos, tmpGFit, battery) := talking(globFitness, gBestPos, neighbours, droneState);
	globFitness := tmpGFit;
	gBestPos := tmpGPos;
	batteryDischarge := battery;
end when;

end PSO;






//Valuta il valore di fitness del singolo drone
function fitness "La fitness value non è altro che la magnitudine tra il drone e la sua destinazione. Se nel percorso si presenta un ostacolo, allora si divide la magnitudine con l'angolo definito tra i 2 vettori"
//posizione droni
InputReal x;
InputReal y;
InputReal z;

InputReal destX, destY, destZ;

//posizione destinazione
InputReal intrX,intrY,intrZ;

OutputReal fitvalue;

	protected 
		Real alpha "Angolo tra i 2 vettori";
		Real dotProd "Prodotto tra 2 punti";
		Real dVector[3] "Vettore tra drone e arrivo";
		Real intrVector[3] "Vettore tra intruso e drone";
		Real fromDtoT "Magnitudine vettore drone-arrivo";
		Real fromDtoIntr "Magnitudine vettore drone-ostacolo";

algorithm
	//Per prima cosa, calcolo l'angolo tra il drone e l'intruso, se presente
	dVector := {destX - x, destY - y, destZ - z};
	intrVector := {intrX - x, intrY-y, intrZ-z};
	dotProd := (dVector[1] * intrVector[1]) + (dVector[2] * intrVector[2]) + (dVector[3] * intrVector[3]); 
	fromDtoT := magnitude(dVector[1], dVector[2], dVector[3]);
	fromDtoIntr := magnitude(intrVector[1],intrVector[2],intrVector[3]);
	alpha := acos(dotProd / (fromDtoT * fromDtoIntr)); 
	fitvalue := (1000*magnitude((destX-x),(destY-y), (destZ-z)))/ alpha;
end fitness;



//La fitness value di un drone viene calcolata basandosi sulla distanza con un ostacolo in movimento (drone nemico, missile, ecc...)
function allFitness

//posizione droni
InputReal x[K.N];
InputReal y[K.N];
InputReal z[K.N];

InputReal destX[K.N], destY[K.N], destZ[K.N];

//posizione destinazione
InputReal intrX[K.nIntr];
InputReal intrY[K.nIntr];
InputReal intrZ[K.nIntr];
InputBool nearIntr[K.N, K.nIntr];

OutputReal fitValue[K.N];

	protected 
		Real tmpFit[K.nIntr];

algorithm 
	fitValue := fill(10000000.0,K.N);
	for i in 1:K.N loop
		tmpFit := zeros(K.nIntr);	
		for j in 1:K.nIntr loop
			if (nearIntr[i,j]) then
				tmpFit[j] := fitness(x[i],y[i],z[i], destX[i], destY[i], destZ[i], intrX[j], intrY[j], intrZ[j]);
			else 
				tmpFit[j] := 1000*magnitude((destX[i]-x[i]), (destY[i]-y[i]), (destZ[i]-z[i]));
			end if;
		end for;
		
		for j in 1:K.nIntr loop
			if (tmpFit[j] < fitValue[i]) then
				fitValue[i] := tmpFit[j];
			end if;
		end for;
	end for;

end allFitness;



//SEZIONE RELATIVA ALLE FUNZIONI DI COMUNICAZIONE PER IL PSO

function talking "Comunicazione relativa alle info del pso"
	
	InputReal gBestFit[K.N];

	InputReal gBestPos[K.N,3];
	
	//Matrice contenente info sui droni vicini tra loro
	InputBool neighbours[K.N,K.N];

	InputInt droneState[K.N];
	
	OutputReal outGbestPos[K.N,3];

	OutputReal outGbestFit[K.N];

	OutputReal battery[K.N];

	protected
		Real tmpBatt[K.N];
	
algorithm
outGbestPos := gBestPos;
outGbestFit := gBestFit;
tmpBatt := zeros(K.N);

for i in 1:K.N loop	
		for j in 1:K.N loop
			if(neighbours[i,j] and i <> j) then
				tmpBatt[i] := tmpBatt[i] + 2;
				if(acknowledgment(droneState[i],droneState[j])) then
					tmpBatt[j] := tmpBatt[j] + 1;
					if(psoComm(gBestFit[i], gBestFit[j])) then //Il drone i ha risposto con valori migliori
						outGbestFit[j] := outGbestFit[j];
						outGbestPos[j,1] := outGbestPos[i,1];
						outGbestPos[j,2] := outGbestPos[i,2];
						outGbestPos[j,3] := outGbestPos[i,3];
					else
						outGbestFit[i] := outGbestFit[j];
						outGbestPos[i,1] := outGbestPos[j,1];
						outGbestPos[i,2] := outGbestPos[j,2];
						outGbestPos[i,3] := outGbestPos[j,3];	
					end if;
				end if;
			end if;
		end for;
end for;

battery := tmpBatt;

end talking;


function acknowledgment "Permette di instaurare una comunicazione tra 2 droni"

InputInt id1,id2;

OutputBool res;

algorithm

res := true;

if(id1 == 3 or id1 == 4) then
	res := false;
	//print("Drone mittente non funzionante\n");
elseif(id2 == 3 or id2 == 4) then
	res := false;
	//print("drone ricevente non funzionante\n");
end if;
end acknowledgment;


function psoComm "Due droni comunicano per scambiare informazioni sull'algoritmo di pathfinding"

//Drone 1

//global fitness
InputReal gBestFit_1;

//Drone 2

InputReal gBestFit_2;


OutputBool gOK;

algorithm

//Se la global fitness del drone 1 è migliore di quella del drone 2, il drone 2 si aggiorna. Altrimenti, il drone 2 manda al drone 1 i suoi valori e il drone 1 deve ripetere la procedura 
gOK := gBestFit_1 <= gBestFit_2;

end psoComm;




