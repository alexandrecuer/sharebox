/*global sb*/
/*global pollselect*/
/*global stringify*/
/*global genfeedback*/
/*global genGroupsAutocompletion*/
/*eslint no-undef: "error"*/
/*eslint no-console: ["error", { allow: ["warn", "error"] }] */

//interrogate the API and generate the list of pending surveys for all the registered users or for a specified group
//possibility to query on a datarange
function gensurveylist()
{
    var request;
    var reqend=[];
    var timeStart=$("#time_start").val();
    var timeEnd=$("#time_end").val();
    var groups=$("#groups").val();
    var pollId=$("#s_poll_id").val();
    if (groups) {
        reqend.push("groups="+groups);
    }
    if (timeStart) {
        reqend.push("time_start="+timeStart);
    }
    if (timeEnd) {
        reqend.push("time_end="+timeEnd);
    }
    if (pollId) {
        reqend.push("poll_id="+pollId);
    }
    var end=reqend.join("&");
    if (end){
        request="/surveys?"+end;
    } else {
        request="/surveys";
    }
    //console.warn(request);
    
    $.ajax({ url: request, 
        dataType: "json", 
        async: true, 
        success(data) {
            var out = [];
            $.each(data, function(index, array){
                if (! array.token.includes("disabled")){
                    var metas=jQuery.parseJSON(array.metas);
                    var color="red";
                    var tracking;
                    if (metas) {
                      if (metas.sent) {
                          color="green";
                          tracking=metas.sent-1;
                      }
                    }
                    out.push("<tr>");
                    out.push("<td><a href=/surveys/"+array.id+"/md5/"+array.token+">"+array.id+"</a><br>S"+array.poll_id+"</td>");
                    var temp="<div style='width:250px; float:left'><b>"+sb["description"]+"</b><br>"+array.description+"</div>";
                    temp+="<div style='width:200px; float:left'><b>"+sb["project_manager"]+"</b><br>"+array.by+"</div>";
                    temp+="<div style='width:200px; float:left'><b>"+sb["client"]+"</b><br>"+array.client_mel+"</div>";
                    temp+="<div style='width:200px; float:left'><b>"+sb["owner"]+"</b><br>"+array.owner_mel+"("+array.user_id+")</div>";
                    temp+="<div style='width:150px; float:left'><b>"+sb["date"]+"</b><br>"+array.created_at.split("T")[0]+"<br>"+sb["last_update"]+": "+array.updated_at.split("T")[0]+"</div>";
                    if (tracking){
                      var label = (tracking===1) ? sb["one_reminder"] : tracking+" "+sb["many_reminders"];
                      temp+="<div style='width:100px; float:left; color:green; background-color:#cff6c0'><b>"+label+"</b></div>";
                    }
                    out.push("<td>"+temp+"</td>");
                    out.push("<td><div style='margin-top: 50%; transform: translateY(-50%);'><button class='send btn-secondary' value="+array.id+" style='background-color:"+color+"'><i class='fa fa-envelope fa-2x' ></i></button></div></td>");
                    out.push("<td><button class='btn' id='deletesurvey"+array.id+"' value="+array.id+">"+sb["delete"]+"</button></td>");
                    out.push("</tr>");
                }                    
            });
            //console.warn(out.join(""));
            $("#surveylist").html(out.join(""));
            
        }
    });
}

function genanswerslinks()
{
    //console.warn("triggering a list of answers");
    $.ajax({ url: "/freelist", 
        dataType: "json", 
        async: true, 
        success(data) {            
            var out = [];
            out.push("<tr><td>");
            var lib;
            var w;
            $.each(data.reverse(), function(index, array){
                if (array.case_number){
                    lib=array.case_number;
                    w=100;
                } else {
                    lib=array.id;
                    w=50;
                }
                out.push("<div style='width:"+w+"px; float:left'><button data-bs-toggle='modal' class='btn btn-link' value='"+array.id+"'>"+lib+"</button></div>");                      
            });
            out.push("</td></tr>");
            $("#answers").html(out); 
        }
    });
}

//validate fields when creating a new survey out of the files/folders system
function validate()
{
    var valid=true;
    
    //description validation
    var description = $("#s_description").val();
    if (description !=="") {
        $("#s_description").css("background-color","#eeffee");
    } else {
        $("#s_description").css("background-color","#ffeeee");
        valid = false;
    }
    
    //email verification
    //var regmel = /^[^\W][a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\@[a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\.[a-zA-Z]{2,4}$/;
    //var regmel = /^([^\W])([a-zA-Z0-9_\-]+)*(\.[a-zA-Z0-9_\-]+)*\@([a-zA-Z0-9_\-]+)(\.[a-zA-Z0-9_\-]+)*\.([a-zA-Z]{2,4})$/;
    var regmel = sb["mel_reg_exp"];
    
    var name = $("#s_client_mel").val();
    var by = $("#s_by").val();
    if (name.match(regmel)){
        $("#s_client_mel").css("background-color","#eeffee");
    } else {
        $("#s_client_mel").css("background-color","#ffeeee");
        valid = false;
    }
    if (by.match(regmel)){
        $("#s_by").css("background-color","#eeffee");
    } else {
        $("#s_by").css("background-color","#ffeeee");
        valid = false;
    }
    
    if (valid) {
        $("#create").show(); 
        //console.warn("all inputs valid");
    } else {
        $("#create").hide();
    }
    
    return valid;
}

var tomorrow= new Date();
tomorrow.setDate(tomorrow.getDate()+1);
var sixmbefore = new Date();
sixmbefore.setMonth(sixmbefore.getMonth() - 6);

$("#time_start").val(stringify(sixmbefore));
$("#time_end").val(stringify(tomorrow));

validate();
gensurveylist();
genanswerslinks();
//setInterval(gensurveylist,5000);

$("#process_options").on("change",".form-control",function(){
    validate();
});

$("#time_start").on("change",function(){
    gensurveylist();
});

$("#time_end").on("change",function(){
    gensurveylist();
});

$("#groups").on("change",function(){
    gensurveylist();
});

//groups autocompletion with the common function
$("#groups").on("input",function(){
  var frag=$(this).val();
  //console.warn(frag);
  genGroupsAutocompletion(frag,"groups");
});

//building select menu with poll names
$.ajax({
    type: "GET",
    url: "/getpolls",
    dataType: "json",
    async: true, 
    success(result) {
        var options=pollselect(result);
        //var options="";
        //$.each(result, function(index, array){
        //    options+="<option value="+array.id+">"+array.name+" (S"+array.id+")</option>";
        //});
        //options+="<select>";
        $("#s_poll_id").html(options);
        //console.warn(options);
        gensurveylist();
    } 
});

$("#s_poll_id").on("input",function(){
    gensurveylist();
});

//manage json output for the create method of the controller
$("#create").click(function(){
    var params = {};
    params["description"]=$("#s_description").val();
    params["client_mel"]=$("#s_client_mel").val();
    params["by"]=$("#s_by").val();
    params["poll_id"]=$("#s_poll_id").val();
    
    if (!validate()) {
        return false;
    }
    
    //console.warn(params);
    
    $.ajax({
        type: "POST",
        url: "/surveys",
        data: params,
        async: true, 
        success(result) { 
            //console.warn(result); 
            gensurveylist();
            $("#create").hide();
            $("#s_description").val("");
            $("#s_description").css("background-color","#ffeeee");
            $("#s_client_mel").val("");
            $("#s_client_mel").css("background-color","#ffeeee");
            $("#s_by").val("");
            $("#s_by").css("background-color","#ffeeee");
        } 
    });
  
});

//basic email autocompletion 
//designed for user or client models, with an 'email' field
function genBasicEmailCompletion(saisie,model,inputId)
{
    $.ajax({
        type: "GET",
        url: "/"+model+"?melfrag="+saisie,
        dataType: "json",
        async: true,
        success(result) {
            var some=[];
            result.forEach(function(r){
                some.push(r["email"]);
            });
            $("#"+inputId).autocomplete({source: some});
        }
    });
}
//email autocompletion on project manager field
$("#s_by").on("input",function(e){
    var saisie = $(this).val();
    //console.warn(saisie);
    genBasicEmailCompletion(saisie,"users","s_by");
});

//email autocompletion on client field
$("#s_client_mel").on("input",function(e){
    var saisie = $(this).val();
    //console.warn(saisie);
    genBasicEmailCompletion(saisie,"clients","s_client_mel");
});

$("#surveylist").on("click",".send",function(){
    var id = $(this).val();
    //console.warn("processing survey "+id);
    $.ajax({
        type: "GET",
        url: "/surveys/"+id+"?email=send",
        async: true,
        success(data) {
            alert(data);
            gensurveylist();
        },
        error(data) {
            alert(data);
        }
    });
});

//implementing action for all .btn 'dynamic' element starting from his ancestor which has to be a static element
$("#surveylist").on("click",".btn",function(){
    var id = $(this).val();
    //console.warn("triggering the deletion of survey "+id);
    $.ajax({
        type: "DELETE",
        url: "/surveys/"+id,
        dataType: "json",
        async: false,
        success(result) {
            //console.warn(result.responseText);
            //gensurveylist();
        },
        error(result) {
            alert(result.responseText);
        }
    });
    gensurveylist();
});

$.ajax({ 
    url: "/getpolls?mynums=1",
    dataType: "json",
    async: true,
    success(data) {
        var answerstitle = sb["feedbacks"];
        data.forEach(function(poll){
            answerstitle+="&nbsp;<a href=/surveys?csv=1&poll_id="+poll+">[CSV_"+sb["poll"]+poll+"_"+sb["yours"]+" "+sb["feedbacks"]+"]</a>";
            answerstitle+="&nbsp;<a href=/surveys?csv=1&poll_id="+poll+"&all=1>[CSV_"+sb["poll"]+poll+"_"+sb["all"]+"]</a>";
        });
        $("#titleandcsv").html(answerstitle);
    }
});
 
$("#answers").on("click",".btn",function(){
    var id = $(this).val();
    //console.warn(id);
    genfeedback(id,"AnswerModal");
});
