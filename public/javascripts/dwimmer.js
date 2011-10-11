var username;
var userid;
var original_content; // to make editor cancellation quick

function _url(url) {
  url = url + '?cache=' + new Date().getTime();
  //alert(url);
  return url;
}

$(document).ready(function() {
  $('#content').show();
  $('#logged_in_bar').hide();
  $('#guest_bar').hide();
  $('#manage-bar').hide();
  $('#manage-bar > div').hide();
  $('#admin').height(0);

  $.getJSON(_url('/_dwimmer/session.json'), function(resp) {
    if (resp["logged_in"] == 1) {
      $('#admin').height("35px");
      $('#admin').show();
      //$('#manage-bar').show();
      $('#logged_in_bar').show();
      $("#logged-in").html(resp["username"]);
      username = resp["username"];
      userid   = resp["userid"];
    } else if (window.location.href.indexOf('?_dwimmer') > 0) {
      $('#admin').height("35px");
      $('#admin').show();
      //$('#manage-bar').show();
      $('#guest_bar').show();
    }
  });

  $(".topnav").dropDownPanels({
    speed: 250,
    resetTimer: 500
  });

  $("form.login").submit(function() {
    var url = "/_dwimmer/login.json";
    $.post(url, $(this).serialize(), function(resp) {
      if (resp["success"] == 1) {
        $('#guest_bar').hide();
        $('#logged_in_bar').show();
        $("#logged-in").html(resp["username"]);
        username = resp["username"];
        userid   = resp["userid"];
      } else {
        alert(resp["error"]);
      }
    }, 'json');
      return false;
    });

    $("#logged-in").click(function() {
      get_and_show_user(userid);
      return false;
    });

    $('.logout').click(function(){
      $.getJSON(_url('/_dwimmer/logout.json'), function(resp) {
        $("#logged-in").html('');
        $('#logged_in_bar').hide();
        $('#manage-bar').hide();
        $('#manage-bar > div').hide();
        $('#manage-display').empty();
        $('#guest_bar').show();
      });
      return false;
    });

    $(".manage").click(function(){
      // TODO do something here?
      return false;
    });

    //get selection from the editor
    //wrap it with <b></b>
    //replace selection with wrapped text
    $("#editor-bold").click(function(){
      insert_markup('b');
    })
    $("#editor-italic").click(function(){
      insert_markup('i');
    })
    $("#editor-link").click(function(){
      var link = prompt('Please paste the link here: (http://www.some.com/ or c:\dir\name\file.txt)');
      if (link) {
        var text = $("#editor_body").getSelection().text;
        if (text == '') {
            $("#editor_body").insertAtCaretPos('<a href="' + link + '">' + link + '</a>');
        } else {
           $("#editor_body").replaceSelection('<a href="' + link + '">' + text + '</a>');
        }
        $('#editor_body').keyup();

        //alert(link);
      }
    })

// show the form
    $(".add_user").click(function(){
      manage_bar();
      $('#manage-add-user').show();
      return false;
    });

    $(".add_page").click(function(){
       manage_bar();
       original_content = $('#content').html();
       $('#create').val( 1 );
       $('#admin-editor').show();
       $('#admin-editor-filename').show();
       $('#editor_body').keyup();    // update preview

       return false;
    });

    $(".create_page").click(function(){
       manage_bar();
       original_content = $('#content').html();
       $('#create').val( 1 );
       $('#admin-editor').show();
       $('#filename').val( $(location).attr('pathname') );
       $('#admin-editor-filename').show();
       $('#editor_body').keyup();    // update preview

       return false;
    });

    $(".create_site").click(function(){
       manage_bar();
       original_content = $('#content').html();
       $('#admin-create-site').show();

       return false;
    });

    $(".create_feed_collector").click(function(){
       manage_bar();
       //original_content = $('#content').html();
       $('#admin-create-feed-collector').show();

       return false;
    });

    $(".create_mailing_list").click(function(){
       manage_bar();
       //original_content = $('#content').html();
       $('#admin-create-mailing-list').show();

       return false;
    });

// submit the form
function submit_form(obj, file) {
	var url = "/_dwimmer/" + file + ".json";
	$.post(url, $(obj).serialize(), function(resp) {
		if (resp["success"] == 1) {
			alert('added');
		} else {
			alert(resp["error"]);
		}
	}, 'json');
	return false;
}

    $("#add_user_form").submit(function() {              return submit_form(this, 'add_user') });
    $("#create_site_form").submit(function() {           return submit_form(this, 'create_site') });
    $("#create_feed_collector_form").submit(function() { return submit_form(this, 'create_feed_collector') });
    $("#create_list_form").submit(function() {           return submit_form(this, 'create_list') });
    $("#add_feed_form").submit(function() {              return submit_form(this, 'add_feed') });

// list values

    $(".list_users").click(function(){
      manage_bar();
      $.getJSON(_url('/_dwimmer/list_users.json'), function(resp) {
        var html = '<ul>';
        for(var i=0; i < resp["users"].length; i++) {
          html += '<li><a href="" value="' + resp["users"][i]["id"]  + '">' + resp["users"][i]["name"] + '</li>';
        }
        html += '</ul>';
        $('#manage-display').show();
        $('#manage-display').html(html);

        // Setup the events only after the html was added!
        $('#manage-display  a').click(function() {
          var value = $(this).attr('value');
          get_and_show_user(value);
          return false;
        });
      });

      return false;
    });


    $(".list_sites").click(function(){
        manage_bar();
        $.getJSON(_url('/_dwimmer/sites.json'), function(resp) {
            var html = '<ul>';
            for(var i=0; i < resp["rows"].length; i++) {
               var title = resp["rows"][i]["name"];
               html += '<li><a href="' + resp["rows"][i]["id"]  + '">' + title + '</li>';
            }
            html += '</ul>';
            $('#manage-display').show();
            $('#manage-display').html(html);
        });

        return false;
    });

    $(".list_pages").click(function(){
        manage_bar();
        $.getJSON(_url('/_dwimmer/get_pages.json'), function(resp) {
            var html = '<ul>';
            for(var i=0; i < resp["rows"].length; i++) {
               var title = resp["rows"][i]["title"] ? resp["rows"][i]["title"] : resp["rows"][i]["filename"];
               html += '<li><a href="' + resp["rows"][i]["filename"]  + '">' + title + '</li>';
            }
            html += '</ul>';
            $('#manage-display').show();
            $('#manage-display').html(html);
        });

        return false;
    });

    $(".list_feed_collectors").click(function(){
        manage_bar();
        $.getJSON(_url('/_dwimmer/feed_collectors.json'), function(resp) {
            var html = '<ul>';
            for(var i=0; i < resp["rows"].length; i++) {
               var title = resp["rows"][i]["name"];
               html += '<li><a href="" value="' + resp["rows"][i]["id"]  + '">' + title + '</a></li>';
            }
            html += '</ul>';
            $('#manage-display').show();
            $('#manage-display').html(html);

            // Setup the events only after the html was added!
            $('#manage-display  a').click(function() {
              var value = $(this).attr('value');
              get_and_show_collector(value);
              return false;
            });

        });
        return false;
    });


   $(".show_history").click(function(){
        manage_bar();
       var url = _url('/_dwimmer/history.json') + '&filename=' + $(location).attr('pathname');
       $.getJSON(url, function(resp) {
            //$('#admin-editor').show();
            var html = '<ul>';
            for(var i=0; i < resp["rows"].length; i++) {
               html += '<li><a class="show_page_rev" href="/_dwimmer/page.json?filename=' + resp["rows"][i]["filename"] + '&revision=' + resp["rows"][i]["revision"]  + '">' + resp["rows"][i]["revision"] + ' ' + resp["rows"][i]["author"] + ' ' + + resp["rows"][i]["timestamp"] + '</li>';
            }
            html += '</ul>';
            $('#manage-display').show();
            $('#manage-display').html(html);

            $(".show_page_rev").click(function() {
                var url = _url( $(this).attr('href') );
                $.getJSON(url, function(resp) {
                    var body = resp["page"]["body"];
                    var revision = resp["page"]["revision"];
                    var html = "<p>Showing revision " + revision  + "<hr></p>" + markup(body);
                    $('#content').html(html); // preview

                    //alert('hi');
                    // show the content of the specific revision of the file
                });
                return false;
            });
        });
        return false;
   });


   // fill editor with content fetched from the server
   $(".edit_this_page").click(function() {
       manage_bar();
       original_content = $('#content').html();
       var url = _url('/_dwimmer/page.json') + '&filename=' + $(location).attr('pathname');
       $.getJSON(url, function(resp) {
            $('#admin-editor').show();
            $('#admin-editor-filename').hide();
            $('#create').val( 0 );
            $('#filename').val( resp["page"]["filename"] );
            $('#editor_title').val( resp["page"]["title"] );
            $('#editor_body').val( resp["page"]["body"] );
            $('#editor_body').keyup();    // update preview
       });
       return false;
   });

    $('#cancel').click(function(){
        $('#editor_title').val('');
        $('#editor_body').val('');
        $('#content').html(original_content);
        original_content = '';
        $('#admin-editor').hide();
        $(".close_manage_bar").click();
        return false;
    });

    $('#save').click(function(){
       var body = $('#editor_body').val();
       var title = $('#editor_title').val();

        var url = '/_dwimmer/save_page.json';
        var data = $("#editor_form").serialize();

        $.post(url, data, function(resp) {
            var data = eval('(' + resp + ')');
            if (data["error"] == "no_file_supplied") {
                alert("Internal error, no filename supplied. Not saved.");
            } else if (data["error"] == "no_site") {
                alert("Internal error, dont know which site are you on.");
            } else { // assume success?
                window.location = $(location).attr('href');
            }
        });

        return false;
    });

    $('#editor_body').keyup(function(){
        var body = $('#editor_body').val();
        var html = markup(body);
        $('#content').html(html); // preview
    });



      $(".close_manage_bar").click(function(){
//        alert("TODO save changes made or alert if not yet saved?");
          $('#manage-display').empty();
          $('#manage-bar').hide();
          return false;
     });
});

function get_and_show_user (value) {
    $.getJSON(_url('/_dwimmer/get_user.json') + '&id=' + value, function(resp) {
        manage_bar();
        var html = '<ul>';
        html += '<li>id = ' + resp["id"] + '</li>';
        html += '<li>name = ' + resp["name"] + '</li>';
        html += '<li>fname = ' + resp["fname"] + '</li>';
        html += '<li>lname = ' + resp["lname"] + '</li>';
        html += '<li>email = ' + resp["email"] + '</li>';
        html += '<li>verified = ' + resp["verified"] + '</li>';
        html += '<li>register_ts = ' + resp["register_ts"] + '</li>';
        html += '</ul>';
        $('#manage-display').show();
        $('#manage-display').html(html);
    });

    return;
}

function get_and_show_collector (value) {
    $.getJSON(_url('/_dwimmer/feeds.json') + '&collector=' + value, function(resp) {
        manage_bar();
        var html = '';
        //html += '<a class="add_feed" href="">add feed</a>';
        html += '<ul>';
        for(var i=0; i < resp["rows"].length; i++) {
           html += '<li><a href="' + resp["rows"][i]["id"] + '">' + resp["rows"][i]["title"] + '</a></li>';
        }
        html += '</ul>';
        $('#admin-add-feed').show();
        //$('#add-feed-form').collector.value( value );
        $('#collector').val( value );

        $('#manage-display').show();
        $('#manage-display').html(html);
    });

    return;
}

function manage_bar() {
        $('#manage-bar').show();
        $('#manage-bar > div').hide();
        $('#manage-display').empty();
        $('#manage-close').show();
        //alert('manage_bar');
}

function markup(text) {
    var html = text;

    // free URL?
    // html = html.replace(/https?:\/\/\S+

    // [link]
    html = html.replace(/\[([\w\/\-]+)\]/g, '<a href="$1">$1</a>');
    return html;
}

function insert_markup(c) {
  if ($("#editor_body").getSelection().text == '') {
     $("#editor_body").insertAtCaretPos('<' + c + '></' + c + '>');
  } else {
     $("#editor_body").replaceSelection('<' + c + '>' + $("#editor_body").getSelection().text + '</' + c + '>');
  }
  $('#editor_body').keyup();
}
