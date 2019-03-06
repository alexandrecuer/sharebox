validate();

$("#process_options").on("change",".form-control",function(){
    validate();
});

function validate()
{
    var valid=true;
    
    //description validation
    var description = $("#s_description").val();
    if (description !="") {
        $("#s_description").css("background-color","#eeffee");
    } else {
        $("#s_description").css("background-color","#ffeeee");
        valid = false;
    }
    
    //email verification
    var regmel = /^[^\W][a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\@[a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\.[a-zA-Z]{2,4}$/;
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
        console.log("all inputs valid");
    } else $("#create").hide();
    
    return valid;
}

//building select menu with poll names
$.ajax({
    type: "GET",
    url: "/getpolls",
    dataType: "json",
    async: true, 
    success: function(result) {
        var options="";
        $.each(result, function(index, array){
            options+="<option value="+array.id+">"+array.name+" (S"+array.id+")</option>";
        });
        options+="<select>";
        $('#s_poll_id').html(options);
        //console.log(options);
    } 
});

//manage json output for the create method of the controller
$("#create").click(function(){
    var params = {};
    params["description"]=$("#s_description").val();
    params["client_mel"]=$("#s_client_mel").val();
    params["by"]=$("#s_by").val();
    params["poll_id"]=$("#s_poll_id").val();
    
    if (!validate()) return false;
    
    console.log(params);
    
    $.ajax({
        type: "POST",
        url: "/surveys",
        data: params,
        async: true, 
        success: function(result) { 
            console.log(result); 
            surveylist_update();
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


//emails autocompletion
$('#s_by').on('input',function(e){
    var saisie = $(this).val();
    //console.log(saisie);
    $.ajax({
        type: "GET",
        url: "/users?melfrag="+saisie,
        dataType: "json",
        async: true,
        success: function(result) {
            var some=[];
            result.forEach(function(r){
                some.push(r["email"]);
            });
            $('#s_by').autocomplete({source: some});
            //console.log(result);
        }      
    });  
});

$('#s_client_mel').on('input',function(e){
    var saisie = $(this).val();
    //console.log(saisie);
    $.ajax({
        type: "GET",
        url: "/clients?melfrag="+saisie,
        dataType: "json",
        async: true,
        success: function(result) {
            var some=[];
            result.forEach(function(r){
                some.push(r["email"]);
            });
            $('#s_client_mel').autocomplete({source: some});
            //console.log(result);
        }     
    });
});

surveylist_update();
answers_update();
//setInterval(surveylist_update,5000);


function surveylist_update()
{
    $.ajax({ url: "/surveys", 
        dataType: 'json', 
        async: true, 
        success: function(data) {
            var out = [];
            $.each(data, function(index, array){
                if (! array.token.includes("disabled")){
                    out.push("<tr>");
                    out.push("<td><a href=/surveys/"+array.id+"/md5/"+array.token+">"+array.id+"</a><br>S"+array.poll_id+"</td>");
                    var temp="<div style='width:250px; float:left'><b>Description</b><br>"+array.description+"</div>";
                    temp+="<div style='width:200px; float:left'><b>Chargé d'affaire</b><br>"+array.by+"</div>";
                    temp+="<div style='width:200px; float:left'><b>Client</b><br>"+array.client_mel+"</div>";
                    temp+="<div style='width:200px; float:left'><b>Propriétaire</b><br>"+array.owner_mel+"("+array.user_id+")</div>";
                    temp+="<div style='width:150px; float:left'><b>Date</b><br>"+array.updated_at.split("T")[0]+"</div>";
                    out.push("<td>"+temp+"</td>");
                    out.push("<td><div style='margin-top: 50%; transform: translateY(-50%);'><button class='send btn-secondary' value="+array.id+"><i class='fa fa-envelope fa-2x' ></i></button></div></td>");
                    out.push("<td><button class='btn' id='deletesurvey"+array.id+"' value="+array.id+">supprimer</button></td>");
                    out.push("</tr>");
                }                    
            });
            //console.log(out.join(''));
            $("#surveylist").html(out);
            
        }
    });
}

$("#surveylist").on("click",".send",function(){
    id = $(this).val();
    console.log("processing survey "+id);
    $.ajax({
        type: "GET",
        url: "/surveys/"+id+"?email=send",
        async: true,
        success: function(data) {
            alert(data);
        },
        error: function(data) {
            alert("data");
        }
    });
});

//implementing action for all .btn 'dynamic' element starting from his ancestor which has to be a static element
$("#surveylist").on("click",".btn",function(){
    id = $(this).val();
    console.log("triggering the deletion of survey "+id);
    $.ajax({
        type: "DELETE",
        url: "/surveys/"+id,
        dataType: "json",
        async: false,
        success: function(result) {
            console.log(result.responseText);
            //surveylist_update();
        },
        error: function(result) {
            console.log(result.responseText);
        }
    });
    surveylist_update();
});

function answers_update()
{
    console.log("triggering a list of answers");
    $.ajax({ url: "/freelist", 
        dataType: 'json', 
        async: true, 
        success: function(data) {            
            var out = [];
            out.push("<tr><td>");
            $.each(data.reverse(), function(index, array){
                out.push("<div style='width:50px; float:left'><button data-toggle='modal' class='btn btn-link' value='"+array.id+"'>"+array.id+"</button></div>");                      
            });
            out.push("</td></tr>");
            $("#answers").html(out); 
        }
    });
}

$("#answers").on("click",".btn",function(){
    id = $(this).val();
    console.log(id);
    $.ajax({ url: "/satisfactions/"+id, 
        dataType: 'json', 
        async: true, 
        success: function(data) {
            var out = "";
            var header = "";
            out+="<table class=table>";
            s=Object.getOwnPropertyNames(data);
            s.forEach(function(val,i){
                if(val=="date" || val=="affaire") header+="<b>"+data[val]+"</b><br>";
                else {
                    numrx=/^[0-9]$/;
                    v=String(data[val]);
                    if (v.match(numrx)) {
                        var note=parseInt(data[val]);
                        var i;
                        out+="<tr><td colspan=2><div class='row align-items-center justify-content-center'>";
                        for (i=0;i<note;i++){
                            out+="<div class='stars'><input type=radio value="+note+" checked='checked'><label class='star-"+note+"'></label></div>";
                        }
                        for (i=note;i<4;i++){
                            out+="<div class='stars'><input type=radio disabled='disabled'><label class='star'></label></div>";
                        }
                        out+="<div class='col-6 col-md-4'>"+val+"</div>";
                        out+="</div></td></tr>";
                    } else
                        out+="<tr><td>"+val+"</td><td>"+data[val]+"</td></tr>";
                }
            });
            out+="</table>";
            $('#mtitle').html(header);
            $('#modal-content').html(out);
            $('#AnswerModal').modal('show');
        }
    });
    
});