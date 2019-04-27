//before using this script, you need to define var poll_id

$('.carousel2').carousel();

var date = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;

//generate the next and previous buttons to navigate through the carousel
function genCarNav(carName)
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
function genFeedbackItem(s)
{
  var satis=[];
  var fields=Object.getOwnPropertyNames(s);
  satis.push("<table width=60% align=center>");
  //to improve - the user experience with this kind of delete button is bad
  var del="<a data-confirm='Etes vous sûr ?' rel='nofollow' data-method='delete' href=/satisfactions/"+s["id"]+"><i class='fa fa-times'></i></a>";
  var closed=[];
  var open=[];
  var j=0;
  closed.push("<tr><td>");
  fields.forEach(function(val){
    switch(val){
      case "id":
        satis.push("<tr><th>Retour satisfaction numéro "+s[val]+del+"</th></tr>");
        break;
      case "affaire":
        satis.push("<tr><th>"+s[val]+"</th></tr>");
        break;
      case "date":
        var when=new Date(s[val]);
        satis.push("<tr><td><i>Enregistré le "+when.toLocaleDateString()+"</i></td></tr>");
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
function genStatsModal(s)
{
  var fields=Object.getOwnPropertyNames(s);
  //console.log(fields);
  rates=Object.getOwnPropertyNames(s[fields[0]]);
  //console.log(rates);
  synth=[];
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

//output a date in human FRENCH format
function dateFormat(d)
{
  var options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
  return new Date(d.substr(0, 10)).toLocaleDateString('fr-FR',options);
}

$("#date_fields").on("change", function(){  
  var timeStart = $("#time_start").val();
  var timeEnd = $("#time_end").val();
  if (timeStart.match(date)) {
    var d1 = new Date(timeStart);
  }
  if (timeEnd.match(date)) {
    var d2 = new Date(timeEnd);
  }
  if (d1 < d2){
    $.ajax({
        type: "GET",
        url: "/satisfactions?poll_id="+pollId+"&start="+timeStart+"&end="+timeEnd,
        async: true,
        success: function(result) {
            //console.log(result);
            stats=[];
            stats.push("<b>"+result.poll_name+"</b><br>");
            stats.push(result.sent);
            stats.push(" questionnaire(s) envoyé(s)<br>");
            stats.push(result.satisfactions.length);
            stats.push("  retour(s) satisfaction<br>");
            stats.push("<a data-toggle='modal' data-target='#synth' href='#'>Voir la synthèse</a><br>");
            stats.push("<a href=/satisfactions?poll_id="+result.poll_id+"&start="+timeStart+"&end="+timeEnd+"&csv=1>Télécharger le fichier csv</a>");
            $("#stats").html(stats.join(""));
            if (result.stats){
              if (Object.keys(result.stats).length>0){
                $("#synth_body").html(genStatsModal(result.stats));
                title=[];
                title.push("Synthèse de l'enquête<br>");
                title.push("<u>"+result.poll_name+"</u>");
                title.push("<br>");
                title.push("Pour la période du "+dateFormat(result.from)+" au "+dateFormat(result.to));
                $("#synth_title").html(title.join(""));
              }
            } else {
              $("#synth_title").html("Il n'y a pas de données....");
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
                out.push(genFeedbackItem(s));
                out.push("</div>");
              });
              $("#carousel-inner").html(out.join(""));
              $("#carousel-nav").html(genCarNav("carousel2"));
            } else {
              $("#carousel-inner").html("");
              $("#carousel-nav").html("");
            }
        }
    });
  }
});