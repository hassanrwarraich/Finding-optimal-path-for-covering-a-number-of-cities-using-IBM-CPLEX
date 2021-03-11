/*********************************************
 * OPL 12.10.0.0 Model
 * Author: The bois
 * Creation Date: 05-Aug-2020 at 4:52:03 PM
 *********************************************/

 //problem size 
 int n = ...;
 int m = ...;
 
 range stops = 1..n;
 range storms = 1..m;
 
 //for location coordinates
 tuple location {
   float x;
   float y;
 }
 
 tuple storm{
   float x;
   float y;
   float radius;
 }
 
 tuple edge{
   int i;
   int j;
 }
 
 /*tuple speed{
   string material;	//road material being used
 }*/
 
 setof(edge) edges = {<i,j> | i,j in stops: i!=j};
 
 //decision variables
 float d[edges]; // distance for each edge
 int v[edges]; //velocity/speed per unit for each edge
 string material[edges]; //material of the road	
 
 //temporary variables
 float a;
 float b;
 float c;
 
 location stopLocation[stops];
 storm stormLocation[storms]; //us
 
 //functions
 execute{
    function calculateDistance(stop1, stop2){
      return (Opl.sqrt(Opl.pow(stop1.x - stop2.x) + Opl.pow(stop1.y-stop2.y)));
      }
      
      //for storm
    function getSemiPerimeter(storm, stop1, stop2){
 	  return (( calculateDistance(stop1, stop2) + calculateDistance(stop1, storm) + calculateDistance(storm, stop2))/2);
 	  }
 	
 	function getHeight(stop1, stop2, storm){
 	  a = (getSemiPerimeter(storm, stop1, stop2) - calculateDistance(stop1, storm));
 	  b = (getSemiPerimeter(storm, stop1, stop2) - calculateDistance(stop2, storm));
 	  c = (getSemiPerimeter(storm, stop1, stop2) - calculateDistance(stop1, stop2));
 	  return ( (2 / calculateDistance(stop1, stop2)) * (Opl.sqrt(getSemiPerimeter(storm, stop1, stop2) * a * b * c)));
 	  } 
 	  
 	function isStorm(stop1,stop2,storm){
 	  if(getHeight(stop1,stop2,storm) > storm.radius){
 	    return 1;
 	  }
 	  else{
 	    if((calculateDistance(stop1, storm) > storm.radius) && (calculateDistance(stop2, storm) > storm.radius)){
 	      return 1;
 	    }
 	    else{
 	      return 0;
 	    }
 	  }
 	}
 	 
 	function getSpeed(speed){
 	  if(speed == 'Asphalt') {
 	  	return 100;
  		} else {
  		  if(speed == 'Gravel') {
  		    return 35;
  		  } else {
  		    return 65;
  		  }
  		}
 	} 
 	 
    for (var e in edges){
 	  d[e] = calculateDistance(stopLocation[e.i], stopLocation[e.j]);
 	  v[e] = getSpeed(material[e]);
 	  y[e] = isStorm(stopLocation[e.i], stopLocation[e.j],stormLocation[e]);
 	  }  
 }
 
 //desicion variables
 dvar boolean y[edges];
 dvar int x[edges];
 
 //expressions
 dexpr float totalTime = sum(e in edges) (d[e] / v[e]) * x[e] * y[e];
 
 minimize totalTime;
 
 //contraints
 subject to{
   forall (j in stops)
     flow_in:
     sum( i in stops : i !=j) x[<i,j>] >= 1;
     
     forall(i in stops)
       flow_out:
       sum( j in stops : j !=i) x[<i,j>] >= 1;
       
     forall(i in stops)
       x[<i,i>] == 0;
       
     forall(i in stops: i>0, j in stops : j>0 && j!=i)
     	y[<i,j>] - y[<j,i>] == 0;
     	
     //no of entries == no of exits
     forall(j in stops)
       sum(i in stops : i>0 && i!=j) ( x[<i,j>] - x[<i,j>]) == 0;
 }