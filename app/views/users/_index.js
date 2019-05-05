//fix the user groups parameters
$(".modifygroups").on("click",function(){
  var params = {};
  params["id"]=$(this).val();
  params["groups"]=$("#groups"+params["id"]).val();
  //console.log(params);
  $.ajax({
    type: "POST",
    url: "/define_groups",
    data: params,
    async: true, 
    success: function(result) { 
      alert(result.message);
    },
    error: function(xhr) { 
      var errorMessage = xhr.status + ": " + xhr.statusText;
      alert("Erreur - " + errorMessage);
    }
  });
});

//groups autocompletion
$(".groups").on("input",function(){
  var frag=$(this).val();
  var id=$(this).attr("id");
  //console.log(id);
  $.ajax({
    type: "GET",
    url: "/get_groups?groupsfrag="+frag,
    dataType: "json",
    async: true,
    success: function(result) {
      $("#"+id).autocomplete({source: result});
    }
  });
});