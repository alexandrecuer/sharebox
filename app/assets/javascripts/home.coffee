viewshare = ->
  $("div[data-sharing]").click () ->
    id = $(this).data("sharing")
    text = $(this).data("folder_name")
    document.getElementById("titre").innerHTML = " Partage du dossier <u>" + text + "</u>" 
    document.getElementById("shared_folder_folder_id").value = id
    $("div#sharingbox").show()
    console.log text+"/"+document.getElementById("sharingbox").style.display

closeshare = ->
  $("a[sharing-close]").click () ->
    $("div#sharingbox").hide()


$(document).on "turbolinks:load", -> viewshare()
$(document).on "turbolinks:load", -> closeshare()
