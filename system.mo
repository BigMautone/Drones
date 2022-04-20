class System

Drone drone;

Controller ctr;

SetPoint p;

MonitorCollision col;

flockingModule flock;

CollisionAvoidance cad;

faultSys fault;

PSO pso;

Intruders intruder;
IntrudersPoint intrP;
IntrController intrCtr;

Rocket rocket;
RocketPointer rockP;
RockController rockCtr;

equation 

	//Connection per i droni
	for i in 1:K.N loop
		
		connect(p.startX[i], drone.startPos[i,1]);
		connect(p.startY[i], drone.startPos[i,2]);
		connect(p.startZ[i], drone.startPos[i,3]);
		connect(p.battery[i], drone.actualCapacity[i]);

		//Connection Controller
		connect(ctr.setx[i],p.setx[i]);
		connect(ctr.sety[i],p.sety[i]);
		connect(ctr.setz[i],p.setz[i]);

		//Passo la posizione del drone al controller
		connect(ctr.x[i],drone.x[i]);
		connect(ctr.y[i],drone.y[i]);
		connect(ctr.z[i],drone.z[i]);

		connect(ctr.Vx[i],drone.Vx[i]);
		connect(ctr.Vy[i],drone.Vy[i]);
		connect(ctr.Vz[i],drone.Vz[i]);
		
		connect(ctr.tmpSetX[i], cad.tmpDestX[i]);
		connect(ctr.tmpSetY[i], cad.tmpDestY[i]);
		connect(ctr.tmpSetZ[i], cad.tmpDestZ[i]);
		connect(ctr.useTMPDest[i], cad.useTMPDest[i]);

		//connection tra info drone e modulo flocking		
		connect(flock.Vx[i],drone.Vx[i]);
		connect(flock.Vy[i],drone.Vy[i]);
		connect(flock.Vz[i],drone.Vz[i]);
		connect(flock.x[i], drone.x[i]);
		connect(flock.y[i], drone.y[i]);
		connect(flock.z[i], drone.z[i]);
		connect(flock.collision, col.outCollision);
		for j in 1:K.N loop
			connect(flock.neighbours[i,j], drone.neighbours[i,j]);
		end for;
		connect(flock.droneState[i], fault.state[i]);

		//Connection tra drone e modulo collision avoidance
		connect(cad.Vx[i],drone.Vx[i]);
		connect(cad.Vy[i],drone.Vy[i]);
		connect(cad.Vz[i],drone.Vz[i]);
		connect(cad.x[i], drone.x[i]);
		connect(cad.y[i], drone.y[i]);
		connect(cad.z[i], drone.z[i]);
		connect(cad.destX[i],p.setx[i]);
		connect(cad.destY[i],p.sety[i]);
		connect(cad.destZ[i],p.setz[i]);
		connect(cad.droneState[i], fault.state[i]);
		connect(cad.nearIntr[i], drone.nearIntr[i]);
		

		//connection tra pso e valori drone + posizione di arrivo
		connect(pso.Vx[i],drone.Vx[i]);
		connect(pso.Vy[i],drone.Vy[i]);
		connect(pso.Vz[i],drone.Vz[i]);
		connect(pso.x[i], drone.x[i]);
		connect(pso.y[i], drone.y[i]);
		connect(pso.z[i], drone.z[i]);
		connect(pso.destX[i],p.setx[i]);
		connect(pso.destY[i],p.sety[i]);
		connect(pso.destZ[i],p.setz[i]);
		for j in 1:K.N loop
			connect(pso.neighbours[i,j], drone.neighbours[i,j]);
		end for;
		connect(pso.nearIntr[i], drone.nearIntr[i]);



		//trasferisco la forza dal controller al drone
		connect(drone.Trustx[i], ctr.Trustx[i]);
		connect(drone.Trusty[i], ctr.Trusty[i]);
		connect(drone.Trustz[i], ctr.Trustz[i]);
		//Trasferisco le velocità calcolate dal monitor di flocking al drone
		connect(drone.alignX[i], flock.alignX[i]);
		connect(drone.alignY[i], flock.alignY[i]);
		connect(drone.alignZ[i], flock.alignZ[i]);
		connect(drone.separateX[i], flock.separateX[i]);
		connect(drone.separateY[i], flock.separateY[i]);
		connect(drone.separateZ[i], flock.separateZ[i]);
		connect(drone.cohesionX[i], flock.cohesionX[i]);
		connect(drone.cohesionY[i], flock.cohesionY[i]);
		connect(drone.cohesionZ[i], flock.cohesionZ[i]);
		//Trasferisco l'heading vector dal pso al drone
		connect(drone.headingX[i], pso.velocityX[i]);
		connect(drone.headingY[i], pso.velocityY[i]);
		connect(drone.headingZ[i], pso.velocityZ[i]);	
		//trasferisco la scarica della batteria dovuta al modulo di comunicazione
		connect(drone.commDischarge[i], pso.batteryDischarge[i]);
		//Asserisco se il drone sta usando la nuova destinazione identificata dal monitor di collision avoidance
		connect(drone.useTMPDest[i], cad.useTMPDest[i]);

		//Connect monitor collisione
		connect(col.x[i], drone.x[i]);
		connect(col.y[i], drone.y[i]);
		connect(col.z[i], drone.z[i]);

		//connection fault system
		connect(drone.droneState[i], fault.state[i]);
		connect(pso.droneState[i], fault.state[i]);
	
		//connection pointer missili con posizione droni
		connect(rockP.droneX[i],drone.x[i]);
		connect(rockP.droneY[i],drone.y[i]);
		connect(rockP.droneZ[i],drone.z[i]);

	end for;
	
	//Connection per gli intruders
	for z in 1:K.nIntr loop
		connect(intrCtr.setx[z],intrP.setx[z]);
		connect(intrCtr.sety[z],intrP.sety[z]);
		connect(intrCtr.setz[z],intrP.setz[z]);

		connect(intrCtr.x[z],intruder.x[z]);
		connect(intrCtr.y[z],intruder.y[z]);
		connect(intrCtr.z[z],intruder.z[z]);

		connect(intrCtr.Vx[z],intruder.Vx[z]);
		connect(intrCtr.Vy[z],intruder.Vy[z]);
		connect(intrCtr.Vz[z],intruder.Vz[z]);

		connect(intruder.Trustx[z], intrCtr.Trustx[z]);
		connect(intruder.Trusty[z], intrCtr.Trusty[z]);
		connect(intruder.Trustz[z], intrCtr.Trustz[z]);

		connect(drone.intrX[z], intruder.x[z]);
		connect(drone.intrY[z], intruder.y[z]);
		connect(drone.intrZ[z], intruder.z[z]);

		connect(pso.intrX[z], intruder.x[z]);
		connect(pso.intrY[z], intruder.y[z]);
		connect(pso.intrZ[z], intruder.z[z]);

		connect(col.intrX[z], intruder.x[z]);
		connect(col.intrY[z], intruder.y[z]);
		connect(col.intrZ[z], intruder.z[z]);

		connect(cad.intrX[z], intruder.x[z]);
		connect(cad.intrY[z], intruder.y[z]);
		connect(cad.intrZ[z], intruder.z[z]);
		connect(cad.vIntrX[z], intruder.Vx[z]);
		connect(cad.vIntrY[z], intruder.Vy[z]);
		connect(cad.vIntrZ[z], intruder.Vz[z]);
	end for;

	//Connection missili
	for q in 1:K.nRocket loop

		connect(rockP.x[q],rocket.x[q]);
		connect(rockP.y[q],rocket.y[q]);
		connect(rockP.z[q],rocket.z[q]);
		
		connect(rockCtr.setx[q],rockP.setx[q]);
		connect(rockCtr.sety[q],rockP.sety[q]);
		connect(rockCtr.setz[q],rockP.setz[q]);

		connect(rockCtr.x[q],rocket.x[q]);
		connect(rockCtr.y[q],rocket.y[q]);
		connect(rockCtr.z[q],rocket.z[q]);

		connect(rockCtr.Vx[q],rocket.Vx[q]);
		connect(rockCtr.Vy[q],rocket.Vy[q]);
		connect(rockCtr.Vz[q],rocket.Vz[q]);

		connect(rocket.Trustx[q], rockCtr.Trustx[q]);
		connect(rocket.Trusty[q], rockCtr.Trusty[q]);
		connect(rocket.Trustz[q], rockCtr.Trustz[q]);


	end for;

end System;
