var lg = "#ececec";
var vlg = "f6f6f6";
var achtung = "ATTENTION ACHTUNG PRUDENCIA ВНИМАНИЕ\n";
//achtung +="___________________________________________________________________________";achtung +="\n";
//achtung +="_ooooo__oo____oo____ooo____ooooooo___ooooooo_ooooooo_____oooo____oo_____oo_";achtung +="\n";
//achtung +="oo___oo_oo____oo__oo___oo__oo____oo__oo______oo____oo__oo____oo___oo___oo__";achtung +="\n";
//achtung +="_oo_____oo____oo_oo_____oo_oo____oo__oooo____oooooooo_oo______oo___oo_oo___";achtung +="\n";
//achtung +="___oo___oooooooo_ooooooooo_ooooooo___oo______oo____oo_oo______oo____ooo____";achtung +="\n";
//achtung +="oo___oo_oo____oo_oo_____oo_oo____oo__oo______oo____oo__oo____oo____oo_oo___";achtung +="\n";
//achtung +="_ooooo__oo____oo_oo_____oo_oo_____oo_ooooooo_ooooooo_____oooo_____oo___oo__";achtung +="\n";
//achtung +="___________________________________________________________________________";achtung +="\n";

//fetch the polls and store them in a list
var polls={};
$.ajax({
    type: "GET",
    url: "/getpolls",
    dataType: "json",
    async: true, 
    success: function(result) {
        polls=result;
        //console.log(polls);
    } 
});


//caution : folder_value is the position in the tree
function childMeta(folderValue,folderId)
{
    var regv=/([0-9]+)/;
    var regi=/folder([0-9]+)/;
    var a = folderValue.match(regv);
    var f = folderId.match(regi);
    //console.log(a);console.log(f);
    if (a && f ) {
      var position = parseInt(a[0],10)+1;
      var parentId = parseInt(f[1],10);
      var tab="";
      for (var i=0;i<position;i++) {
        tab+="&nbsp;&nbsp;";
      }
      var results={};
      results["parent_id"]=parentId;
      results["level"]=position;
      results["tab"]=tab;
      return results;
    } else {
      return false;
    }
}

//below are functions which generate html outputs from a given json object
//these are link, list or tabs functions
function linka(asset,currentuser)
{
    size=Math.round(asset.uploaded_file_file_size/(1024*102.4))/10;
    var link= "";
    link+="<tr><td>";
    link+="<div class='d-flex align-items-center flex-row-reverse bd-highlight mb-3'>";
    if (currentuser.id==asset.user_id) {
        link+="<button class='btn btn-outline-danger btn-sm' rel='nofollow' id=delete_asset value="+asset.id+">Supprimer</button>";
    } else {
        link+="("+asset.user_name+")";
    }
    link+="</div>";
    link+="</td><td>";
    link+="<div class=file><a href=/forge/get/"+asset.id+">"+asset.uploaded_file_file_name+"</a><b>&nbsp;["+size+"&nbsp;Mo]</b></div>";
    link+="</td></tr>";
    return link;
}

function linkf(folder,currentuser)
{
    var link="";
    link+="<tr><td>";
    link+="<div class='d-flex align-items-center flex-row-reverse bd-highlight mb-3'>";
    if (currentuser.id==folder.user_id) {
        link+="<button class='btn btn-outline-danger btn-sm' rel='nofollow' id=delete_folder value="+folder.id+">Supprimer</button>";
    } else {
        link+="("+folder.user_name+")";
    }
    link+="</div>";
    link+="</td><td>";
    link+="<div class=folder value="+folder.id+">"+folder.name+"</div>";
    link+="</td></tr>";
    return link;
}    

function shareslist(shares)
{
    var slist=[];
    if (shares.length>0) {
        slist.push("<table class='table table-sm'>");
        slist.push("<tr><td colspan=3>Partages</td></tr>");
        shares.forEach(function(share){
            slist.push("<tr><td>");
            slist.push("<button rel='nofollow' id=delete_share value="+share.id+">Supprimer</button>");
            slist.push("</td><td>");
            slist.push("Partage "+share.id+" - "+share.share_email+" ("+share.share_user_id+")");
            slist.push("</td><td>");
            slist.push("<button id=contact_customer class='send btn-secondary' value="+share.share_email+"><i class='fa fa-envelope fa-1x' ></i></button>");
            slist.push("</td></tr>");
        });
        slist.push("</table>");
    }
    //console.log(slist.join(''));
    return slist.join('');
}

//create all the tabs necessary to manage a given folder or root
function createtabs(folder,shares,satis,currentuser)
{
    var tabs="";
    tabs+="<ul class='nav nav-tabs' id=manage_tabs role=tablist>";
    if (folder.id>=0) {
        tabs+="<li class=nav-item>";
        tabs+="<button id=go_up class=btn value="+folder.parent_id+"><i class='fa fa-arrow-up fa-1x' style='color:lightgrey'></i></button>";
        tabs+="</li>";
        if (currentuser.id==folder.user_id){
          tabs+="<li class=nav-item>";
          tabs+="<a class=nav-link id=manage-tab data-toggle=tab href=#manage_folder role=tab aria-controls=manage_folder>Gérer dossier</a>";
          tabs+="</li>";
        }
    }
    tabs+="<li class=nav-item>";
    tabs+="<a class='nav-link' id=folder-tab data-toggle=tab href=#new_folder role=tab aria-controls=new_folder>Créer sous-dossier</a>";
    tabs+="</li>";
    tabs+="<li class=nav-item>";
    tabs+="<a class=nav-link id=asset-tab data-toggle=tab href=#new_asset role=tab aria-controls=new_asset>Charger un fichier</a>";
    tabs+="</li>";
    if (satis.length>0) {
        tabs+="<li class=nav-item>";
        tabs+="<a class=nav-link id=satis-tab data-toggle=tab href=#satisfactions role=tab aria-controls=satisfactions>Retours satisfactions</a>";
        tabs+="</li>";
    }
    tabs+="</ul>";
   
    tabs+="<div class=tab-content id=alltabs>";
   
    //new subfolder form
    tabs+="<div class='tab-pane fade' id=new_folder role=tabpanel><br>";
    tabs+="<input type=text class=form-control id=folder_name placeholder='nom du répertoire'><br>";
    tabs+="<input type=text class=form-control id=folder_case_number placeholder='N°affaire'>";
    if (folder.id>=0) {
        tabs+="<input type=hidden class=form-control id=folder_parent_id value="+folder.id+">";
    }
    tabs+="<br><button id=create_folder class=btn style=display:none>Créer le répertoire</button>";
    tabs+="</div>";
   
    //asset form
    tabs+="<div class='tab-pane fade' id=new_asset role=tabpanel><br>";
    tabs+="<form method=POST enctype=multipart/form-data id=assetUploadForm>";
    //tabs+="<input type=hidden name='authenticity_token' value=<%= form_authenticity_token %>>";
    tabs+="<input class=form-control-file type=file id=asset_uploaded_file name=asset[uploaded_file]>";
    if (folder.id>=0) {
        tabs+="<input type=hidden id=asset_folder_id name=asset[folder_id] value="+folder.id+">";
    }
    tabs+="</form>";
    tabs+="<br><button id=create_asset class=btn style=display:none>Charger le fichier</button>";
    tabs+="</div>";
   
    // manage folder form
    if (folder.id>=0) {
      if (currentuser.id==folder.user_id){
        tabs+="<div class='tab-pane fade' id=manage_folder role=tabpanel><br>";
        tabs+="<input type=hidden id=currentfolder_id value="+folder.id+">";
        tabs+='<input type=text class=form-control id=currentfolder_name placeholder="nom du répertoire" value="'+folder.name+'"><br>';
        tabs+='<input type=text class=form-control id=currentfolder_case_number placeholder="Numéro d\'affaire" value="'+folder.case_number+'">';
        
        var options="<br><select class='form-control' id=currentfolder_poll_id>";
        options+="<option value=''>choisissez un sondage</option>";
        if (polls.length>0) {
          polls.forEach(function(poll){
            var tag=" "
            if (folder.poll_id === poll.id) {
               tag=" selected";
            }
            options+="<option value="+poll.id+tag+">"+poll.name+" (S"+poll.id+")</option>";
          });
        }
        options+="</select>";
        tabs+=options;
        tabs+="<br><button type=submit class=btn id=currentfolder_modify>Sauvegarder les modifications</button><br><br>";
        
        //manage the shares
        tabs+="<div id=shareslist>";
        tabs+=shareslist(shares);
        tabs+="</div>";
        tabs+='<input type=text class="form-control" id=shared_folder_share_email placeholder="Si partage vers plusieurs adresses, utilisez la virgule comme séparateur ,">';
        tabs+='<br><button type=submit class=btn id=add_shares>Ajouter un ou plusieurs partages</button>';
        tabs+='&nbsp;<button type=reset class=btn id=reset_shares>Effacer saisie</button>';
        tabs+="</div>";
      }
        
      //view satisfaction answers
      if (satis.length>0) {
        tabs+="<div class='tab-pane fade' id=satisfactions role=tabpanel>";
        tabs+="<table class='table table-sm'>";
        tabs+="<thead><td>Vous avez "+satis.length+" retour(s)</td></thead>";
        tabs+="<tr><td>";
        satis.forEach(function(sat){
            tabs+="<div style='width:50px; float:left' class=satis value="+sat.id+">&nbsp;<i class='fa fa-eye fa-2x'></i></div>";
        });
        tabs+="</td></tr></table>";
        tabs+="<div>";
      }
        
    }
    tabs+="</div>";
    return tabs;
}

function subfoldersassetslist(data)
{
    var list="";
    var hidden="";
    //when interrogating the API through list on the root, API return current_folder.id =-1
    if (data.currentuser.id==data.currentfolder.user_id || data.currentfolder.id<0) {
      title=data.currentfolder.name;
    } else {
      title=data.currentfolder.name+"<br>Dossier appartenant à "+data.currentfolder.user_name+"&nbsp;(utilisateur "+data.currentfolder.user_id+")";
    }
    list+="<div class='table-responsive-sm'>";
    list+="<table class=table><thead><td colspan=2 bgcolor="+lg+"><div id=folder_title>"+title+"</div></td></thead>";
    list+="<tr><td colspan=2>"+hidden+"</td></tr>";
    list+="<tr><td colspan=2 bgcolor="+vlg+">";
    list+=createtabs(data.currentfolder,data.currentfoldershares,data.currentfoldersatis,data.currentuser);
    list+="</td></tr>";
    data.subfolders.forEach(function(folder){
        list+=linkf(folder,data.currentuser);
    });
    data.assets.forEach(function(asset){
        list+=linka(asset,data.currentuser);
    });
    list+="</table>";
    list+="</div>";
    return list;
}

//to materialize the status of the folder with a colored icon - shared = green - has satisfaction answers = orange
function icontofolder(lists)
{
    var icon="";
    if (lists.shares.length>0) {
        if (lists.satis.length>0) {
            icon="&nbsp;<i class='fas fa-circle' style='color:orange'></i>";
        } else {
            icon="&nbsp;<i class='fas fa-circle' style='color:green'></i>";
        }
    }
    return icon;
}

//update a fragment in the tree_view if it exists
//folder_lists is already supposed to be a json object not a string
function fragment(folder_id,folder_name,folder_lists)
{
    if ($("#tree_view").find("#folder"+folder_id).length>0) {
        var level=$("#tree_view").find("#folder"+folder_id).attr('value');
        //console.log("regenerating a fragment on level "+level);
        var tab="";
        for (var i=0;i<level;i++) {
            tab+="&nbsp;&nbsp;";
        }
        $("#tree_view").find("#folder"+folder_id).html(tab+"|_"+folder_name+icontofolder(folder_lists));
    }
}

//interrogate the API and regenerate a fragment of the tree_view if it exists
function genfragment(folder_id)
{
    if ($("#tree_view").find("#folder"+folder_id).length>0) {
      $.ajax({
        type: "GET",
        url: "/browse?id="+folder_id,
        async: true,
        success: function(result) {
            //console.log(result);
            lists=JSON.parse(result.lists);
            fragment(folder_id,result.name,lists);
        }
      });
    }
}

//interrogate the API and initialize on 'root' both tree_view and folder_view
function genrootview()
{
    $.ajax({ 
        url: "/list",
        dataType: "json",
        async: true,
        success: function (data) {
            console.log(data);
            var root_name=data.currentfolder.name;
            var root_tree = "";
            root_tree="<div class=root>"+root_name+"</div>";
            data.subfolders.forEach(function(folder){
              var lists=JSON.parse(folder.lists);
              root_tree+="<div class='child' id=folder"+folder.id+" value=1>&nbsp;&nbsp;|_"+folder.name+icontofolder(lists)+"</div>";
              root_tree+="<div id=child"+folder.id+"></div>";
            });
            root_tree+="<div class=shared_root>dossiers partagés</div>";
            data.sharedfoldersbyothers.forEach(function(folder){
              var lists=JSON.parse(folder.lists);
              root_tree+="<div class='child' id=folder"+folder.id+" value=1>&nbsp;&nbsp;|_"+folder.name+icontofolder(lists)+"</div>";
              root_tree+="<div id=child"+folder.id+"></div>";
            });
            root_tree+="<br>";
            $("#tree_view").html(root_tree);
            $("#folder_view").html(subfoldersassetslist(data));
            $(".root").css("background-color", lg);
        }
    });
}

//interrogate the API and update the folder_view div
function genfolderview(folder_id)
{
    var myurl;
    console.log("regenerating folder view for folder "+folder_id);
    if (folder_id) {
        myurl="/list?id="+folder_id;
    } else {
        myurl="/list";
    }
    $.ajax({ 
        url: myurl,
        dataType: "json",
        async: true,
        success: function (data) {
            console.log(data);
            if (data.currentfolder.id){
                $("#folder_view").html(subfoldersassetslist(data));
            } else {
                alert(data.currentfolder.name);
            }
        }
    });
}

//interrogate the API and update the sharelist div
function genshareslist(folder_id)
{
    $.ajax({
        type: "GET",
        url: "/getshares/"+folder_id,
        dataType: "json",
        async: true,
        success: function(data) {
            //console.log(data);
            var list=shareslist(data);
            //console.log(list);
            $("#shareslist").html(list);
            $("#shared_folder_share_email").val("");
        }
    });
}

$("#tree_view").css('border-right', '1px solid lightgrey');

genrootview();

//regenerate the root view whenever asked by the user
$("#tree_view").on("click",".root",function(){
    genrootview();
});

//oldfashion style navigation
$("#folder_view").on("click","#go_up",function(){
    parent_id=parseInt($(this).val());
    console.log(parent_id);
    genfolderview(parent_id);
});

//user click on a folder icon in folder_view
$("#folder_view").on("click",".folder",function(){
    //console.log($(this).attr('value'));
    genfolderview($(this).attr('value'));
});

//show submit button to upload a new asset
$("#folder_view").on("change","#asset_uploaded_file",function(){
    var asset = $("#asset_uploaded_file").val();
    if (asset) {
        $("#create_asset").show();
    }
});

//show submit button to create a new folder
$("#folder_view").on("change","#folder_name",function(){
    var folder = $("#folder_name").val();
    if (folder) {
        $("#create_folder").show();
    } else {
        $("#create_folder").hide();
    }
});

//show satisfaction feedback
//the surveyfeedback function is in shared/colibritoolbox.js
$("#folder_view").on("click",".satis", function(){
    //satis is a div you cannot use val()
    var id = $(this).attr('value');
    //console.log(id);
    surveyfeedback(id,"AnswerModal");
});

//reset input text field for shares
$("#folder_view").on("click","#reset_shares", function(){
    $("#shared_folder_share_email").val("");
});

$("#folder_view").on("click","#contact_customer",function(){
    var email=$(this).val();
    var folder_id = $("#currentfolder_id").val();
    $.ajax({
        type: "GET",
        url: "/contact_customer/"+folder_id+"?share_email="+email,
        async: true,
        success: function(result) {
            //console.log(result);
            alert(result.message);
        }
      });
    
});

//*************************
//update an existing folder
$("#folder_view").on("click","#currentfolder_modify", function(){
    var params = {};
    params["id"]=$("#currentfolder_id").val();
    params["name"]=$("#currentfolder_name").val();
    params["case_number"]=$("#currentfolder_case_number").val();
    params["poll_id"]=$("#currentfolder_poll_id").val();
    console.log(params);
    $.ajax({
        type: "POST",
        url: "/update_folder",
        data: params,
        async: true, 
        success: function(result) { 
            alert(result.message);
            if (result.success) {
              //we have to update the corresponding line in the tree_view if really browsed
              var lists=JSON.parse(result.lists);
              fragment(params["id"],params["name"],lists);
              //we have to update the folder title in the folder view
              $("#folder_title").html(params["name"]);
            }
        },
        error: function(xhr) { 
            var errorMessage = xhr.status + ': ' + xhr.statusText
            alert('Erreur - ' + errorMessage);
        }
    });        
});

//emails autocompletion for sharing process
$("#folder_view").on("input", "#shared_folder_share_email",function(){
    var saisie = $(this).val();
    //console.log(saisie);
    var last = saisie.split(",").pop().trim();
    //console.log("last fragment:"+last);
    $.ajax({
        type: "GET",
        url: "/users?melfrag="+last,
        dataType: "json",
        async: true,
        success: function(result) {
            var some=[];
            result.forEach(function(r){
                some.push(r["email"]);
            });
            //console.log(some);
            $('#shared_folder_share_email').autocomplete({
                source: function(request,response) {
                    response($.ui.autocomplete.filter(some,last));
                },
                select: function(event,ui) {
                    var terms = this.value.split(",");
                    // remove the current input
                    terms.pop();
                    // add the selected item
                    terms.push(ui.item.value);
                    // add placeholder to get the comma-and-space at the end
                    terms.push("");
                    this.value = terms.join(",");
                    return false;
                }
            });
        }      
    });  
});

//add new shares to the current_folder
$("#folder_view").on("click", "#add_shares", function(){
    var params={};
    params["share_email"]=$("#shared_folder_share_email").val();
    params["folder_id"]=$("#currentfolder_id").val();
    console.log(params);
    $.ajax({
        type: "POST",
        url: "/share",
        data: params,
        async: true, 
        success: function(result) { 
            alert(result.message);
            if (result.success) {
              console.log("regenerating shares list and fragment if any");
              genshareslist(params["folder_id"]);
              genfragment(params["folder_id"]);
            }
        }
    });
});

//delete an existing share
$("#folder_view").on("click","#delete_share", function(){
  var share_id = $(this).val();
  var folder_id=$("#currentfolder_id").val();
  $.ajax({
    type: "delete",
    url: "/deleteshare/"+folder_id+"/"+share_id,
    async: true, 
    beforeSend: function(){
        var message=achtung+"\nVous êtes sur le point de supprimer un partage\n\n";
        message+="Etes vous sûr ?";
        return confirm(message);
    },
    success: function(result) { 
        alert(result.message);
        if (result.success) {
          console.log("regenerating shares list and fragment if any");
          genshareslist(folder_id);
          genfragment(folder_id);
        }
    }
  });    
});

//create a new folder
$("#folder_view").on("click","#create_folder",function(){
    var params={};
    params["name"]=$("#folder_name").val();
    params["case_number"]=$("#folder_case_number").val();
    params["parent_id"]=$("#folder_parent_id").val();
    console.log(params);
    $.ajax({
        type: "POST",
        url: "/create_folder",
        async: true,
        data: params,
        success: function(result) {
            alert(result.message);
            if (result.success) {
                //2 different cases : root or non root
                if (params["parent_id"]) {
                  genfolderview(params["parent_id"]);
                  //if fragment of parent folder is visible, we have to add a new child corresponding to the new folder
                  if ($("#tree_view").find("#folder"+params["parent_id"]).length>0) {
                    var level=parseInt($("#tree_view").find("#folder"+params["parent_id"]).attr('value'))+1;
                    console.log("generating a new fragment on level "+level);
                    var tab="";
                    for (var i=0;i<level;i++) {
                      tab+="&nbsp;&nbsp;";
                    }
                    folder_tree=$("#child"+params["parent_id"]).html();
                    //console.log(folder_tree);
                    //console.log(tab);
                    folder_tree+="<div class=child id=folder"+result.folder_id+" value='"+level+"'>"+tab+"|_"+params["name"]+"</div>";
                    folder_tree+="<div id=child"+result.folder_id+"></div>";
                    //console.log(folder_tree);
                    $("#child"+params["parent_id"]).html(folder_tree);
                  }
                } else {
                  genrootview();
                }
            }
        }
    });
});

//delete a folder
$("#folder_view").on("click","#delete_folder",function(){
    folder_id=$(this).val();
    console.log(folder_id);
    $.ajax({
        type: "DELETE",
        url: "/delete_folder/"+folder_id,
        async: true,
        beforeSend: function(){
            var message=achtung+"\nVous êtes sur le point de supprimer un répertoire\n";
            message+="Tous les objets associés (partages,retours satisfaction,sous-dossiers,fichiers) seront détruits\n";
            message+="Cette action est irréversible\n\n";
            message+="Etes vous sûr ?";
            return confirm(message);
        },
        success: function(result) {
            alert(result.message);
            if (result.success) {
                genfolderview(result.parent_id);
                //we remove the fragment in case....
                if ($("#tree_view").find("#folder"+folder_id).length>0) {
                    $("#folder"+folder_id).remove();
                    $("#child"+folder_id).remove();
                }
            }
        },
        error: function(result) {
            alert(result);
        }
    });
});

//user upload a new asset
$("#folder_view").on("click","#create_asset",function(){
    //$("#create_asset").replaceWith("<i class='fa fa-spinner fa-pulse fa-3x fa-fw'></i>");
    $("#create_asset").html("<i class='fa fa-spinner fa-pulse fa-3x fa-fw'></i>");
    file=$("#assetUploadForm")[0];
    var datafile = new FormData(file); 
    var folder_id=$("#folder_parent_id").val();
    
    $.ajax({
        type: "POST",
        processData: false,  // Important!
        contentType: false,
        //cache: false,
        url: "/upload_asset",
        data: datafile,
        async: true, 
        success: function(result) { 
            if (folder_id) {
              alert("répertoire "+folder_id+"\n"+result.message);
            } else {
              alert("répertoire racine\n"+result.message);
            }
            if (result.success) {
              genfolderview(folder_id);
            } else {
              $("#asset_uploaded_file").val("");
              $("#create_asset").html("Charger le fichier");
              $("#create_asset").hide();
            }
        },
        error: function(result) {
            alert(result);
        }
    });
});

//delete an asset
$("#folder_view").on("click","#delete_asset",function(){
    var id=$(this).val();
    var currentfolder_id=$("#currentfolder_id").val();
    console.log("asset number "+id+" in folder "+currentfolder_id+" is going to be deleted"); 
    $.ajax({
        type: "DELETE",
        url: "/delete_asset/"+id,
        async: true,
        beforeSend: function(){
            var message=achtung+"\nVous êtes sur le point de supprimer un fichier\n";
            message+="Cette action est irréversible\n\n";
            message+="Etes vous sûr ?";
            return confirm(message);
        },
        success: function(result) {
            alert(result.message);
            if (result.success) {
                genfolderview(currentfolder_id);
            }
        },
        error: function(result) {
            alert(result);
        }
    });
});

//update folder_tree in tree_view while exploring step by step
$("#tree_view").on("click",".child",function(){
    //var text = $(this).text();
    var meta = childMeta($(this).attr('value'), $(this).attr('id'));
    var value = meta.parent_id;
    $(".root").css("background-color","#ffffff");
    $(".child").each(function() {
      $(this).css("background-color","#ffffff");
    });
    $(this).css("background-color",lg);
    console.log("we are on folder "+value);
    console.log("corresponding metas are:");
    console.log(meta);
    var folder_tree = "";
    $.ajax({ 
      url: "/list?id="+value,
      dataType: "json",
      async: true,
      success: function (data) {
        console.log(data);
        data.subfolders.forEach(function(folder){
          var lists=JSON.parse(folder.lists);
          folder_tree+="<div class=child id=folder"+folder.id+" value='"+meta.level+"'>"+meta.tab+"|_"+folder.name+icontofolder(lists)+"</div>";
          folder_tree+="<div id=child"+folder.id+"></div>";
        });
        $("#child"+value).html(folder_tree);
        $("#folder_view").html(subfoldersassetslist(data));    
      }
    });      
});