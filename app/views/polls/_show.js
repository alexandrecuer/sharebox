/*global sb*/
/*global humandate*/
/*global stringify*/
/*global pollselect*/
/*global genGroupsAutocompletion*/
/*eslint no-undef: "error"*/

//$(".carousel2").carousel();
var date = sb["date_reg_exp"];

//generate the next and previous buttons to navigate through the carousel
function carouselnav(carName)
{
  var nav=[];
  nav.push("<a class='carousel-control-prev' href='#"+carName+"' role='button' data-slide='prev'>");
  nav.push("<i class='fa fa-chevron-left' style='color:black'></i>");
  nav.push("</a>");
  nav.push("<a class='carousel-control-next' href='#"+carName+"' role='button' data-slide='next'>");
  nav.push("<i class='fa fa-chevron-right' style='color:black'></i>");
  nav.push("</a>");
  return nav.join("");
}

//generate the satisfaction feedback html output using colored box buttons
function feedbackpostcard(s)
{
  var satis=[];
  var fields=Object.getOwnPropertyNames(s);
  satis.push("<table width=60% align=center>");
  //to improve - the user experience with this kind of delete button is bad
  var del="<a data-confirm='"+sb["are_yu_sure"]+"' rel='nofollow' data-method='delete' href=/satisfactions/"+s["id"]+"><i class='fa fa-times'></i></a>";
  var closed=[];
  var open=[];
  var j=0;
  closed.push("<tr><td>");
  fields.forEach(function(val){
    switch(val){
      case "id":
        satis.push("<tr><th>"+sb["feedback_number"]+" "+s[val]+del+"</th></tr>");
        break;
      case "affaire":
        satis.push("<tr><th>"+s[val]+"</th></tr>");
        break;
      case "date":
        var when=new Date(s[val]);
        satis.push("<tr><td><i>"+sb["recorded_on"]+" "+when.toLocaleDateString()+"</i></td></tr>");
        break;
      case "collected_by":
        break;
      case "folder_id":
        break;
      case "folder_name":
        break;
      case "poll_id":
        break;
      default:
        if (Number.isInteger(s[val])){
          if (Number.isInteger(j / 3)) {
            closed.push("<br>");
          }
          j++;
          switch(s[val]){
            case 4:
              closed.push("<button type=button class='btn btn-success btn-sm'>");
              break;
            case 3:
              closed.push("<button type=button class='btn btn-info btn-sm'>");
              break;
            case 2:
              closed.push("<button type=button class='btn btn-warning btn-sm'>");
              break;
            case 1:
              closed.push("<button type=button class='btn btn-danger btn-sm'>");
              break;
          }
          closed.push(val+"</button>");
        } else {
          open.push("<tr><td>");
          open.push("<i>"+val+"</i><br>");
          open.push(s[val]);
          open.push("</td></tr>");
        }
    }
  });
  closed.push("</td></tr>");
  satis.push(closed.join(""));
  satis.push(open.join(""));
  satis.push("</table>");
  return satis.join("");
}

//generate the stats as a html table for the modal
function synthmodal(s)
{
  var i;
  var fields=Object.getOwnPropertyNames(s);
  //console.log(fields);
  var rates=Object.getOwnPropertyNames(s[fields[0]]);
  //console.log(rates);
  var synth=[];
  synth.push("<table class='table table-striped table-bordered table-hover table-sm'><tr><td></td>");
  for (i=0;i<rates.length;i++){
    synth.push("<td>"+rates[i]+"</td>");
  }
  synth.push("</tr>");
  
  fields.forEach(function(f){
    synth.push("<tr><td>");
    synth.push(f);
    synth.push("</td>");
    for (i=0;i<rates.length;i++){
      synth.push("<td>"+s[f][rates[i]]+" %</td>");
    }
    synth.push("</tr>");
    //console.log(s[f]);
  });
  //console.log(synth);
  return synth.join("");
}


//full output stats generation for a given pollId, ie number of sent surveys, number of feedbacks received, synth modal and carousel
function genstatsforpoll(pollId)
{
  var groups=$("#groups").val();
  var timeStart = $("#time_start").val();
  var timeEnd = $("#time_end").val();
  var d1;
  var d2;
  if (timeStart.match(date)) {
    d1 = new Date(timeStart);
  }
  if (timeEnd.match(date)) {
    d2 = new Date(timeEnd);
  }
  var tab=[];
  var base="/satisfactions/run/"+pollId;
  var request;
  if (groups) { tab.push("groups="+groups); }
  if (d1 < d2) { tab.push("start="+timeStart+"&end="+timeEnd); }
  var end=tab.join("&");
  if (end.length>0){
    request=base+"?"+end;
  } else {
    request=base;
  }
  //console.log(request);
  var csvlink;
  var ncaplink;
  //console.log(request.indexOf("?"));
  if (request.indexOf("?") > 0){
    csvlink=request+"&csv=1";
    ncaplink=request+"&csv=1&ncap=2";
  } else {
    csvlink=request+"?csv=1";
    ncaplink=request+"?csv=1&ncap=2";
  }
    
  $.ajax({
    type: "GET",
    url: request,
    async: true,
    success(result) {
        var stats=[];
        stats.push("<b>"+result.poll_name+"</b><br>");
        stats.push(result.sent);
        stats.push(" "+sb["sent_surveys"]+"<br>");
        stats.push(result.satisfactions.length);
        stats.push("  "+sb["feedbacks"]+"<br>");
        stats.push("<a data-toggle='modal' data-target='#synth' href='#'>"+sb["check_summary"]+"</a><br>");
        stats.push("<a href="+csvlink+">"+sb["download_csv"]+"</a><br>");
        stats.push("<a href="+ncaplink+">"+sb["ncap"]+"&nbsp;2</a>");
        $("#stats").html(stats.join(""));
        if (result.stats){
          if (Object.keys(result.stats).length>0){
            $("#synth_body").html(synthmodal(result.stats));
            var title=[];
            title.push(sb["poll_summary"]);
            title.push("<br><u>"+result.poll_name+"</u>");
            if (result.from && result.to) {
              title.push("<br>"+sb["period"]+" "+sb["from"]+" "+humandate(result.from)+" "+sb["to"]+" "+humandate(result.to));
            } else {
              title.push("<br>"+sb["from_poll_start"]);
            }
            if (result.groups) {
              title.push("<br>"+sb["for_group"]+" "+result.groups);
            }
            $("#synth_title").html(title.join(""));
          }
        } else {
          $("#synth_title").html(sb["no_data" ]);
          $("#synth_body").html("");
        }
        if (result.satisfactions.length>0){
          var out=[];
          result.satisfactions.forEach(function(s,i){
            //generate the carrousel item
            if (i===0){
              out.push("<div class='carousel-item active'>");
            } else {
              out.push("<div class='carousel-item'>");
            }
            out.push(feedbackpostcard(s));
            out.push("</div>");
          });
          $("#carousel-inner").html(out.join(""));
          $("#carousel-nav").html(carouselnav("carousel2"));
          //test on 10/05/2019
          $("#carousel2").carousel();
        } else {
          $("#carousel-inner").html("");
          $("#carousel-nav").html("");
        }
    }
  });
}

var pollId;
var polls={};

var tomorrow= new Date();
tomorrow.setDate(tomorrow.getDate()+1);
var sixmbefore = new Date();
sixmbefore.setMonth(sixmbefore.getMonth() - 6);


$("#time_start").val(stringify(sixmbefore));
$("#time_end").val(stringify(tomorrow));

//interrogate the API and store the poll json list in the polls global var
//realize the stats initialization with the poll with highest id
$.ajax({
    type: "GET",
    url: "/getpolls",
    dataType: "json",
    async: true, 
    success(result) {
        polls=result;
        var ids=[];
        polls.forEach(function(p){
          ids.push(p.id);
        });
        //console.log(...ids);
        pollId=Math.max(...ids);
        $("#s_poll_id").html(pollselect(polls,pollId));
        genstatsforpoll(pollId);
    } 
});

$("#s_poll_id").on("change", function(){  
  pollId=$("#s_poll_id").val();
  //console.log(pollId);
  genstatsforpoll(pollId);
});

$("#date_fields").on("change", function(){  
  genstatsforpoll(pollId);
});

//use keypress?
$("#groups").on("change", function(event){  
  //var frag=$(this).val();
  //console.log(event.which+" for the entry "+frag)
  genstatsforpoll(pollId);
});

//groups autocompletion with the common function
$("#groups").on("input",function(){
  var frag=$(this).val();
  //console.log(frag);
  genGroupsAutocompletion(frag,"groups");
});
