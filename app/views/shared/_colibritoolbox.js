/*global sb*/
/*global conf*/
/*eslint no-undef: "error"*/

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
                    header+="<b>"+data[val]+"</b><br>";
                } else {
                    var numrx=/^[0-9]$/;
                    var v=String(data[val]);
                    //console.log(v);
                    if (v.match(numrx)) {
                        var note=parseInt(data[val],10);
                        //console.log(note);
                        var i;
                        out+="<tr><td colspan=2><div>";
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
                        out+=val+"</td></tr>";
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
//if selectId is given, we build a full select component and we do not use conf["main_poll_number"] to initialize a default entry
//if selectId is not given, we build an the list of options to be integrated as an html in a empty select component already existing in a view 
//in that case, we use conf["main_poll_number"] to initialize a default entry, for lazy users...
function pollselect(polls,selectedPollId,selectId)
{
var options=[];
if (selectId){
  options.push("<select class='form-control' id="+selectId+">");
}
if (!selectId && !selectedPollId && conf["main_poll_number"]){
    selectedPollId=conf["main_poll_number"];
}
options.push("<option value=''>"+sb["choose_poll"]+"</option>");
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

//output a date in human FRENCH format
function humandate(d)
{
  var options = { weekday: "long", year: "numeric", month: "long", day: "numeric" };
  return new Date(d.substr(0, 10)).toLocaleDateString(sb["lang"],options);
}

//returns a date string as expected in the range (time_start and time_end)
function stringify(date) 
{
    var d = new Date(date);
    var month = "" + (d.getMonth() + 1);
    
    var day = "" + d.getDate();
    var year = d.getFullYear();

    if (month.length < 2) {
        month = "0" + month;
    }
    if (day.length < 2) {
        day = "0" + day;
    }

    return [year, month, day].join("-");
}

//groups autocompletion elaborate process given a text fragment and an inputId field where to autocomplete
//different from what is realized by _index.js in the users control panel
function genGroupsAutocompletion(frag,inputId)
{
  $.ajax({
    type: "GET",
    url: "/get_groups?groupsfrag="+frag,
    dataType: "json",
    async: true,
    success(result) {
      var some=[];
      result.forEach(function(r){
        var elements=r.split("/");
        elements.forEach(function(e){
          if (!result.includes(e)){
              result.push(e);
          }
        });
      });
      //console.log(result);
      $("#"+inputId).autocomplete({source: result});
    }
  });
}
//*******************************END******OF******COMMON*****JS*****FUNCTIONS***********************************
