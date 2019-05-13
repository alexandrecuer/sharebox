//generate the users list according to some filtering parameters
function genUserList(groups,statut,melfrag)
{
var tab=[];
var base="/users";
var request;
if (groups) { tab.push("groups="+groups); }
if (statut) { tab.push("statut="+statut); }
if (melfrag) { tab.push("melfrag="+melfrag); }
tab.push("admin="+1);
var end=tab.join("&");
if (end.length>0){
  request=base+"?"+end;
} else {
  request=base;
}
$.ajax({
    type: "GET",
    url: request,
    dataType: "json",
    async: true,
    success(result) {
      $("#users_summary").html("<h5>[gestion des utilisateurs]["+result.length+"]</h5>");
      tab=[];
      result.forEach(function(u){
        var practises=[];
        if (u.has_shares) { practises.push(u.has_shares) ;}
        if (u.is_sharing) { practises.push(u.is_sharing) ;}
        if (u.groups===null) { u.groups=""; }
        var options;
        options="<option value=admin>admin</option><option value=private>private</option><option value=public>public</option>";
        switch(u.statut){
          case "admin" : 
            options=options.replace("value=admin","selected value=admin");
            break;
          case "private":
            options=options.replace("value=private","selected value=private");
            break;
          case "public":
            options=options.replace("value=public","selected value=public");
            break;
        }
        tab.push("<tr>");
        tab.push("<td>"+u.id+"</td>");
        tab.push("<td><a href=/become/"+u.id+">"+u.email+"</a></td>");
        tab.push("<td>"+practises.join("/")+"</td>");
        tab.push("<td><select id=statut"+u.id+">"+options+"</select><button id=statutmod value="+u.id+">changer status</button></td>");
        tab.push("<td>");
        //class is needed for autocompletion
        tab.push("<input type=text class=groups id=groups"+u.id+" placeholder=dir./dpt./grp./unit./? value="+u.groups+">");
        tab.push("<button id=modifygroups type=submit value="+u.id+">Modifier groupe</button>");
        tab.push("</td>");
        tab.push("<td><a data-confirm='Etes vous sûr?' rel=nofollow data-method=delete href=/users/"+u.id+">Supprimer</a></td>"); 
        tab.push("</tr>");
      });
      $("#users_list").html(tab.join(""));
    }
});
}

function dothemaj(){
  var groups=$("#groups").val();
  var statut=$("#statut").val();
  var melfrag=$("#melfrag").val();
  genUserList(groups,statut,melfrag);
}

genUserList();

$("#groups").on("change",function(){
  dothemaj();
});

$("#melfrag").on("change",function(){
  dothemaj();
});

$("#statut").on("change",function(){
  dothemaj();
});

//modify the statut of a user
$("#users_list").on("click","#statutmod",function(){
  var params = {};
  params["id"]=$(this).val();
  params["statut"]=$("#statut"+params["id"]).val();
  //console.log(params["id"]+" wants to become "+params["statut"]);
  $.ajax({
    type: "PATCH",
    url: "/users/"+params["id"],
    data: params,
    dataType: "json",
    async: true,
    success(result) {
      alert (result.message);
    },
    error(xhr) { 
      var errorMessage = xhr.status + ": " + xhr.statusText;
      alert("Erreur - " + errorMessage);
    }
  });
});

//fix the user 'groups' parameter
$("#users_list").on("click","#modifygroups",function(){
  var params = {};
  params["id"]=$(this).val();
  params["groups"]=$("#groups"+params["id"]).val();
  //console.log(params);
  $.ajax({
    type: "POST",
    url: "/define_groups",
    data: params,
    async: true, 
    success(result) { 
      alert(result.message);
    },
    error(xhr) { 
      var errorMessage = xhr.status + ": " + xhr.statusText;
      alert("Erreur - " + errorMessage);
    }
  });
});

//groups autocompletion on text input of each user
$("#users_list").on("input",".groups",function(){
  var frag=$(this).val();
  var id=$(this).attr("id");
  //console.log(id);
  $.ajax({
    type: "GET",
    url: "/get_groups?groupsfrag="+frag,
    dataType: "json",
    async: true,
    success(result) {
      $("#"+id).autocomplete({source: result});
    }
  });
});

//groups autocompletion with the common function for filtering
$("#groups").on("input",function(){
  var frag=$(this).val();
  genGroupsAutocompletion(frag,"groups");
});