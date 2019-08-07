var lg = "#ececec";
var vlg = "f6f6f6";
var achtung = "ATTENTION ACHTUNG PRUDENCIA ВНИМАНИЕ\n";
/*global sb*/
/*global pollselect*/
/*eslint no-undef: "error"*/
var polls={};

//interrogate the API and store the poll json list in the polls global var
$.ajax({
    type: "GET",
    url: "/getpolls",
    dataType: "json",
    async: true, 
    success(result) {
        polls=result;
        //console.log(polls);
    } 
});

//basic text format
function f(text)
{
    return text.replace(/'/,"&#039;");
}

//caution : folder_value is the position in the tree
function childmeta(folderValue,folderId)
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
    var size=Math.round(asset.uploaded_file_file_size/(1024*102.4))/10;
    var link= [];
    link.push("<tr><td>");
    link.push("<div class='d-flex align-items-center flex-row-reverse bd-highlight mb-3'>");
    if (currentuser.id===asset.user_id) {
        link.push("<button class='btn btn-outline-danger btn-sm' rel='nofollow' id=delete_asset value="+asset.id+">"+sb["delete"]+"</button>");
    } else {
        link.push("("+asset.user_name+")");
    }
    link.push("</div>");
    link.push("</td><td>");
    link.push("<div class=file><a href=/forge/get/"+asset.id+">"+asset.uploaded_file_file_name+"</a><b>&nbsp;["+size+"&nbsp;Mo]</b></div>");
    link.push("</td></tr>");
    return link.join("");
}

function linkf(folder,currentuser)
{
    var link=[];
    link.push("<tr><td>");
    link.push("<div class='d-flex align-items-center flex-row-reverse bd-highlight mb-3'>");
    if (currentuser.id===folder.user_id) {
        link.push("<button class='btn btn-outline-danger btn-sm' rel='nofollow' id=delete_folder value="+folder.id+">"+sb["delete"]+"</button>");
    } else {
        link.push("("+folder.user_name+")");
    }
    link.push("</div>");
    link.push("</td><td>");
    link.push("<div class=folder value="+folder.id+">"+folder.name+"</div>");
    link.push("</td></tr>");
    return link.join("");
}    

function shareslist(shares)
{
    var slist=[];
    if (shares.length>0) {
        slist.push("<table class='table table-sm'>");
        slist.push("<tr><td colspan=3>"+sb["shares"]+"</td></tr>");
        shares.forEach(function(share){
            slist.push("<tr><td>");
            slist.push("<button rel='nofollow' id=delete_share value="+share.id+">"+sb["delete"]+"</button>");
            slist.push("</td><td>");
            slist.push(sb["share_number"]+" "+share.id+" - "+share.share_email+" ("+share.share_user_id+")");
            slist.push("</td><td>");
            slist.push("<button id=contact_customer class='send btn-secondary' value="+share.share_email+"><i class='fa fa-envelope fa-1x' ></i></button>");
            slist.push("</td></tr>");
        });
        slist.push("</table>");
    }
    return slist.join("");
}

//create all the tabs necessary to manage a given folder or root
function createtabs(folder,shares,satis,currentuser)
{
    var tabs=[];
    tabs.push("<ul class='nav nav-tabs' id=manage_tabs role=tablist>");
    if (folder.id>=0) {
        tabs.push("<li class=nav-item>");
        tabs.push("<button id=go_up class=btn value="+folder.parent_id+"><i class='fa fa-arrow-up fa-1x' style='color:lightgrey'></i></button>");
        tabs.push("</li>");
        if (currentuser.id===folder.user_id){
          tabs.push("<li class=nav-item>");
          tabs.push("<a class=nav-link id=manage-tab data-toggle=tab href=#manage_folder role=tab aria-controls=manage_folder>"+sb["manage"]+" "+sb["folder"]+"</a>");
          tabs.push("</li>");
        }
    }
    tabs.push("<li class=nav-item>");
    tabs.push("<a class='nav-link' id=folder-tab data-toggle=tab href=#new_folder role=tab aria-controls=new_folder>"+sb["create"]+" "+sb["subfolder"]+"</a>");
    tabs.push("</li>");
    tabs.push("<li class=nav-item>");
    tabs.push("<a class=nav-link id=asset-tab data-toggle=tab href=#new_asset role=tab aria-controls=new_asset>"+sb["upload"]+" "+sb["file"]+"</a>");
    tabs.push("</li>");
    if (satis.length>0) {
        tabs.push("<li class=nav-item>");
        tabs.push("<a class=nav-link id=satis-tab data-toggle=tab href=#satisfactions role=tab aria-controls=satisfactions>"+sb["feedbacks"]+"</a>");
        tabs.push("</li>");
    }
    tabs.push("</ul>");
   
    tabs.push("<div class=tab-content id=alltabs>");
   
    //new subfolder form
    tabs.push("<div class='tab-pane fade' id=new_folder role=tabpanel><br>");
    tabs.push("<input type=text class=form-control id=folder_name placeholder='"+sb["folder_name"]+"'><br>");
    tabs.push("<input type=text class=form-control id=folder_case_number placeholder='"+f(sb["case_number"])+"'>");
    if (folder.id>=0) {
        tabs.push("<input type=hidden class=form-control id=folder_parent_id value="+folder.id+">");
    }
    tabs.push("<br><button id=create_folder class=btn style=display:none>"+sb["create"]+"</button>");
    tabs.push("</div>");
   
    //asset form
    tabs.push("<div class='tab-pane fade' id=new_asset role=tabpanel><br>");
    tabs.push("<form method=POST enctype=multipart/form-data id=assetUploadForm>");
    //tabs+="<input type=hidden name='authenticity_token' value=<%= form_authenticity_token %>>";
    tabs.push("<input class=form-control-file type=file id=asset_uploaded_file name=asset[uploaded_file]>");
    if (folder.id>=0) {
        tabs.push("<input type=hidden id=asset_folder_id name=asset[folder_id] value="+folder.id+">");
    }
    tabs.push("</form>");
    tabs.push("<br><button id=create_asset class=btn style=display:none>"+sb["upload"]+" "+sb["file"]+"</button>");
    tabs.push("</div>");
   
    // manage folder form
    if (folder.id>=0) {
      if (currentuser.id===folder.user_id){
        tabs.push("<div class='tab-pane fade' id=manage_folder role=tabpanel><br>");
        tabs.push("<input type=hidden id=currentfolder_id value="+folder.id+">");
        tabs.push("<input type=text class=form-control id=currentfolder_name placeholder='"+sb["folder_name"]+"' value='"+f(folder.name)+"'><br>");
        tabs.push("<input type=text class=form-control id=currentfolder_case_number placeholder='"+f(sb["case_number"])+"' value='"+folder.case_number+"'>");
        var options=pollselect(polls,folder.poll_id,"currentfolder_poll_id");
        tabs.push("<br>"+options);
        tabs.push("<br><button type=submit class=btn id=currentfolder_modify>"+sb["save_mod"]+"</button><br><br>");
        
        //manage the shares
        tabs.push("<div id=shareslist>");
        tabs.push(shareslist(shares));
        tabs.push("</div>");
        tabs.push("<input type=text class=form-control id=shared_folder_share_email placeholder='"+sb["share_label"]+"'>");
        tabs.push("<br><button type=submit class=btn id=add_shares>"+sb["add_one_or_more_shares"]+"</button>");
        tabs.push("&nbsp;<button type=reset class=btn id=reset_shares>"+sb["reset"]+"</button>");
        tabs.push("</div>");
      }
        
      //view satisfaction answers
      if (satis.length>0) {
        tabs.push("<div class='tab-pane fade' id=satisfactions role=tabpanel>");
        tabs.push("<table class='table table-sm'>");
        tabs.push("<thead><td>"+sb["you_have"]+" "+satis.length+" "+sb["feedbacks"]+"</td></thead>");
        tabs.push("<tr><td>");
        satis.forEach(function(sat){
            tabs.push("<div style='width:50px; float:left' class=satis value="+sat.id+">&nbsp;<i class='fa fa-eye fa-2x'></i></div>");
        });
        tabs.push("</td></tr></table>");
        tabs.push("<div>");
      }
        
    }
    tabs.push("</div>");
    return tabs.join("");
}

function subfoldersassetslist(data)
{
    var list="";
    var hidden="";
    var title;
    //when interrogating the API through list on the root, API return current_folder.id =-1
    if (data.currentuser.id===data.currentfolder.user_id || data.currentfolder.id<0) {
      title=data.currentfolder.name;
    } else {
      title=data.currentfolder.name+"<br>"+sb["owner"]+" : "+data.currentfolder.user_name+"&nbsp;("+sb["user"]+" "+sb["id"]+" "+data.currentfolder.user_id+")";
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
//folderLists is already supposed to be a json object not a string
function fragment(folderId,folderName,folderLists)
{
    if ($("#tree_view").find("#folder"+folderId).length>0) {
        var level=$("#tree_view").find("#folder"+folderId).attr("value");
        //console.log("regenerating a fragment on level "+level);
        var tab="";
        for (var i=0;i<level;i++) {
            tab+="&nbsp;&nbsp;";
        }
        $("#tree_view").find("#folder"+folderId).html(tab+"|_"+folderName+icontofolder(folderLists));
    }
}

//interrogate the API and regenerate a fragment of the tree_view if it exists
function genfragment(folderId)
{
    if ($("#tree_view").find("#folder"+folderId).length>0) {
      $.ajax({
        type: "GET",
        url: "/browse?id="+folderId,
        async: true,
        success(result) {
            //console.log(result);
            var lists=JSON.parse(result.lists);
            fragment(folderId,result.name,lists);
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
        success(data) {
            //console.log(data);
            var rootName=data.currentfolder.name;
            var rootTree = "";
            rootTree="<div class=root>"+rootName+"</div>";
            data.subfolders.forEach(function(folder){
              var lists=JSON.parse(folder.lists);
              rootTree+="<div class='child' id=folder"+folder.id+" value=1>&nbsp;&nbsp;|_"+folder.name+icontofolder(lists)+"</div>";
              rootTree+="<div id=child"+folder.id+"></div>";
            });
            $.ajax({
                url: "/i18n?field=shared",
                dataType: "json",
                async: true,
                success(d){
                  //console.log(d);
                  rootTree+="<div class=shared_root>"+d.result+"</div>";
                  data.sharedfoldersbyothers.forEach(function(folder){
                    var lists=JSON.parse(folder.lists);
                    rootTree+="<div class='child' id=folder"+folder.id+" value=1>&nbsp;&nbsp;|_"+folder.name+icontofolder(lists)+"</div>";
                    rootTree+="<div id=child"+folder.id+"></div>";
                 });
                 rootTree+="<br>";
                 $("#tree_view").html(rootTree);
                 $("#folder_view").html(subfoldersassetslist(data));
                 $(".root").css("background-color", lg);
                }
            });
            
        }
    });
}

//interrogate the API and update the folder_view div
function genfolderview(folderId)
{
    var myurl;
    //console.log("regenerating folder view for folder "+folderId);
    if (folderId) {
        myurl="/list?id="+folderId;
    } else {
        myurl="/list";
    }
    $.ajax({ 
        url: myurl,
        dataType: "json",
        async: true,
        success(data) {
            //console.log(data);
            if (data.currentfolder.id){
                $("#folder_view").html(subfoldersassetslist(data));
            } else {
                alert(data.currentfolder.name);
            }
        }
    });
}

//interrogate the API and update the sharelist div
function genshareslist(folderId)
{
    $.ajax({
        type: "GET",
        url: "/getshares/"+folderId,
        dataType: "json",
        async: true,
        success(data) {
            //console.log(data);
            var list=shareslist(data);
            //console.log(list);
            $("#shareslist").html(list);
            $("#shared_folder_share_email").val("");
        }
    });
}

$("#tree_view").css("border-right", "1px solid lightgrey");

genrootview();

//regenerate the root view whenever asked by the user
$("#tree_view").on("click",".root",function(){
    genrootview();
});

//oldfashion style navigation
$("#folder_view").on("click","#go_up",function(){
    var parentId=parseInt($(this).val(),10);
    //console.log(parentId);
    genfolderview(parentId);
});

//user click on a folder icon in folder_view
$("#folder_view").on("click",".folder",function(){
    //console.log($(this).attr("value"));
    genfolderview($(this).attr("value"));
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
//the genfeedback function is in shared/colibritoolbox.js
$("#folder_view").on("click",".satis", function(){
    //satis is a div you cannot use val()
    var id = $(this).attr("value");
    //console.log(id);
    genfeedback(id,"AnswerModal");
});

//reset input text field for shares
$("#folder_view").on("click","#reset_shares", function(){
    $("#shared_folder_share_email").val("");
});

//contact a customer
$("#folder_view").on("click","#contact_customer",function(){
    var email=$(this).val();
    var folderId = $("#currentfolder_id").val();
    $.ajax({
        type: "GET",
        url: "/contact_customer/"+folderId+"?share_email="+email,
        async: true,
        success(result) {
            //console.log(result);
            alert(result.message);
        },
        error(xhr) { 
            var errorMessage = xhr.status + ": " + xhr.statusText;
            alert(sb["failure"]+" - " + errorMessage);
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
    //console.log(params);
    $.ajax({
        type: "POST",
        url: "/update_folder",
        data: params,
        async: true, 
        success(result) { 
            alert(result.message);
            if (result.success) {
              //we have to update the corresponding line in the tree_view if really browsed
              var lists=JSON.parse(result.lists);
              fragment(params["id"],params["name"],lists);
              //we have to update the folder title in the folder view
              $("#folder_title").html(params["name"]);
            }
        },
        error(xhr) { 
            var errorMessage = xhr.status + ": " + xhr.statusText;
            alert(sb["failure"]+" - " + errorMessage);
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
        success(result) {
            var some=[];
            result.forEach(function(r){
                some.push(r["email"]);
            });
            //console.log(some);
            $("#shared_folder_share_email").autocomplete({
                source(request,response) {
                    response($.ui.autocomplete.filter(some,last));
                },
                select(event,ui) {
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
    //console.log(params);
    $.ajax({
        type: "POST",
        url: "/share",
        data: params,
        async: true, 
        success(result) { 
            alert(result.message);
            if (result.success) {
              //console.log("regenerating shares list and fragment if any");
              genshareslist(params["folder_id"]);
              genfragment(params["folder_id"]);
            }
        }
    });
});

//delete an existing share
$("#folder_view").on("click","#delete_share", function(){
  var shareId = $(this).val();
  var folderId=$("#currentfolder_id").val();
  $.ajax({
    type: "delete",
    url: "/deleteshare/"+folderId+"/"+shareId,
    async: true, 
    beforeSend(){
        var message=achtung+"\n"+sb["going_to_delete_share"]+"\n\n";
        message+=sb["are_yu_sure"];
        return confirm(message);
    },
    success(result) { 
        alert(result.message);
        if (result.success) {
          //console.log("regenerating shares list and fragment if any");
          genshareslist(folderId);
          genfragment(folderId);
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
    //console.log(params);
    $.ajax({
        type: "POST",
        url: "/create_folder",
        async: true,
        data: params,
        success(result) {
            alert(result.message);
            if (result.success) {
                //2 different cases : root or non root
                if (params["parent_id"]) {
                  genfolderview(params["parent_id"]);
                  //if fragment of parent folder is visible, we have to add a new child corresponding to the new folder
                  if ($("#tree_view").find("#folder"+params["parent_id"]).length>0) {
                    var level=parseInt($("#tree_view").find("#folder"+params["parent_id"]).attr("value"),10)+1;
                    //console.log("generating a new fragment on level "+level);
                    var tab="";
                    for (var i=0;i<level;i++) {
                      tab+="&nbsp;&nbsp;";
                    }
                    var folderTree=$("#child"+params["parent_id"]).html();
                    //console.log(folderTree);
                    //console.log(tab);
                    folderTree+="<div class=child id=folder"+result.folder_id+" value='"+level+"'>"+tab+"|_"+params["name"]+"</div>";
                    folderTree+="<div id=child"+result.folder_id+"></div>";
                    //console.log(folderTree);
                    $("#child"+params["parent_id"]).html(folderTree);
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
    var folderId=$(this).val();
    //console.log(folderId);
    $.ajax({
        type: "DELETE",
        url: "/delete_folder/"+folderId,
        async: true,
        beforeSend(){
            var message=achtung+"\n"+sb["going_to_delete_folder"]+"\n";
            message+=sb["all_children_are_to_be_deleted"]+"\n";
            message+=sb["no_way_back"]+"\n\n";
            message+=sb["are_yu_sure"];
            return confirm(message);
        },
        success(result) {
            alert(result.message);
            if (result.success) {
                genfolderview(result.parent_id);
                //we remove the fragment in case....
                if ($("#tree_view").find("#folder"+folderId).length>0) {
                    $("#folder"+folderId).remove();
                    $("#child"+folderId).remove();
                }
            }
        },
        error(result) {
            alert(result);
        }
    });
});

//user upload a new asset
$("#folder_view").on("click","#create_asset",function(){
    //$("#create_asset").replaceWith("<i class='fa fa-spinner fa-pulse fa-3x fa-fw'></i>");
    $("#create_asset").html("<i class='fa fa-spinner fa-pulse fa-3x fa-fw'></i>");
    var file=$("#assetUploadForm")[0];
    var datafile = new FormData(file); 
    var folderId=$("#folder_parent_id").val();
    
    $.ajax({
        type: "POST",
        processData: false,  // Important!
        contentType: false,
        //cache: false,
        url: "/upload_asset",
        data: datafile,
        async: true, 
        success(result) { 
            if (folderId) {
              alert(sb["folder"]+" "+folderId+"\n"+result.message);
            } else {
              alert(sb["root_folder"]+"\n"+result.message);
            }
            if (result.success) {
              genfolderview(folderId);
            } else {
              $("#asset_uploaded_file").val("");
              $("#create_asset").html(sb["upload"]);
              $("#create_asset").hide();
            }
        },
        error(result) {
            alert(result);
        }
    });
});

//delete an asset
$("#folder_view").on("click","#delete_asset",function(){
    var id=$(this).val();
    var currentfolderId=$("#currentfolder_id").val();
    //console.log("asset number "+id+" in folder "+currentfolderId+" is going to be deleted"); 
    $.ajax({
        type: "DELETE",
        url: "/delete_asset/"+id,
        async: true,
        beforeSend(){
            var message=achtung+"\n"+sb["going_to_delete_file"]+"\n";
            message+=sb["no_way_back"]+"\n\n";
            message+=sb["are_yu_sure"];
            return confirm(message);
        },
        success(result) {
            alert(result.message);
            if (result.success) {
                genfolderview(currentfolderId);
            }
        },
        error(result) {
            alert(result);
        }
    });
});

//update folder_tree in tree_view while exploring step by step
$("#tree_view").on("click",".child",function(){
    //var text = $(this).text();
    var meta = childmeta($(this).attr("value"), $(this).attr("id"));
    var value = meta.parent_id;
    $(".root").css("background-color","#ffffff");
    $(".child").each(function() {
      $(this).css("background-color","#ffffff");
    });
    $(this).css("background-color",lg);
    //console.log("we are on folder "+value);
    //console.log("corresponding metas are:");
    //console.log(meta);
    var folderTree = "";
    $.ajax({ 
      url: "/list?id="+value,
      dataType: "json",
      async: true,
      success(data) {
        //console.log(data);
        data.subfolders.forEach(function(folder){
          var lists=JSON.parse(folder.lists);
          folderTree+="<div class=child id=folder"+folder.id+" value='"+meta.level+"'>"+meta.tab+"|_"+folder.name+icontofolder(lists)+"</div>";
          folderTree+="<div id=child"+folder.id+"></div>";
        });
        $("#child"+value).html(folderTree);
        $("#folder_view").html(subfoldersassetslist(data));    
      }
    });      
});