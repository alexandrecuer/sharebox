function resolve(json,val) {
    return json[val];
}

//interrogate the API and show a given satisfaction feedback in a specific modal 
//note the modal must have a header with id=mtitle and a body with id=mcontent
function genfeedback(id,modalId)
{
    var out = "";
    var header = "";
    $.ajax({ url: "/satisfactions/json/"+id, 
        dataType: "json", 
        async: true, 
        success(data) {
            //console.log(data);
            out+="<table class=table>";
            var s=Object.getOwnPropertyNames(data);
            s.forEach(function(val){
                if(val==="date" || val==="affaire") {
                    header+="<b>"+resolve(data,val)+"</b><br>";
                } else {
                    var numrx=/^[0-9]$/;
                    var v=String(data[val]);
                    //console.log(v);
                    if (v.match(numrx)) {
                        var note=parseInt(data[val],10);
                        //console.log(note);
                        var i;
                        out+="<tr><td colspan=2><div class='row align-items-center justify-content-center'>";
                        if (!note) {
                          for (i=0;i<4;i++){
                            out+="<div class='stars'><input type=radio disabled='disabled'><label class='star'></label></div>";
                          }  
                        } else {
                          //console.log(note)
                          for (i=1;i<=note;i++){
                            out+="<div class='stars'><input type=radio value="+note+" checked='checked'><label class='star-"+note+"'></label></div>";
                          }
                          for (i=note+1;i<=4;i++){
                            out+="<div class='stars'><input type=radio disabled='disabled'><label class='star'></label></div>";
                          }
                        }
                        out+="<div class='col-6 col-md-4'>"+val+"</div>";
                        out+="</div></td></tr>";
                    } else {
                        out+="<tr><td>"+val+"</td><td>"+data[val]+"</td></tr>";
                    }
                }
            });
            out+="</table>";
            $("#mtitle").html(header);
            $("#mcontent").html(out);
            $("#"+modalId).modal("show");
        }
    });
}

//generate html output to create a select menu for choosing the active poll
//used in different views (browse, surveys, polls)
function pollselect(polls,selectedPollId,selectId)
{
var options=[];
if (selectId){
  options.push("<select class='form-control' id="+selectId+">");
}
options.push("<option value=''>choisissez un sondage</option>");
if (polls.length>0) {
  polls.forEach(function(poll){
    var tag=" ";
    if (selectedPollId === poll.id) {
      tag=" selected";
      }
    options.push("<option value="+poll.id+tag+">"+poll.name+" (S"+poll.id+")</option>");
    });
  }
if (selectId){
  options.push("</select>");
}
return options.join("");
}
