// Fonction qui va permettre de calculer automatiquement le nombre de questions ouvertes et fermées en fonction du nombre de ; dans les textarea. 

function calc_names_number(){

	var areaclosednumber = document.createElement("textarea");
	var areaopennumber = document.createElement("textarea");

	areaclosednumber.style.display = "none";
	areaopennumber.style.display = "none";
	
	if (document.getElementById("poll_closed_names").value == "" )
		areaclosednumber.value = 0;
	else
		areaclosednumber.value = document.getElementById("poll_closed_names").value.split(";").length;
	
	if (document.getElementById("poll_open_names").value == "" )
		areaopennumber.value = 0;
	else 
		areaopennumber.value = document.getElementById("poll_open_names").value.split(";").length;

	areaclosednumber.setAttribute("name","poll[closed_names_number]");
	areaopennumber.setAttribute("name","poll[open_names_number]");

	var form = document.getElementsByTagName('form')[0];
	form.appendChild(areaclosednumber);
	form.appendChild(areaopennumber);
}