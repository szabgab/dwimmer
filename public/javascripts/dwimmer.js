var username;
var userid;
var original_content; // to make editor cancellation quick

 $(document).ready(function() {
   $('#content').show();
   $('#logged_in_bar').hide();
   $('#guest_bar').hide();
   $('#manage-bar').hide();
   $('#manage-bar > div').hide();
   
//   $('#manage-bar div').hide();
//   $('#manage-bar').show();
//   $('#manage-display').html('editor_body');
//   $('#manage-display').show();
//   $('#manage-close').show();

   $.getJSON('/_dwimmer/session.json', function(resp) {
       if (resp["logged_in"] == 1) {
           $('#logged_in_bar').show();
           $("#logged-in").html(resp["username"]);
           username = resp["username"];
           userid   = resp["userid"];
       } else {
           $('#guest_bar').show();
       }
   });

   // fill editor with content fetched from the server
   $(".edit_this_page").click(function() {
       manage_bar();
       original_content = $('#content').html();
       var url = '/_dwimmer/page.json?filename=' + $(location).attr('pathname');
       $.getJSON(url, function(resp) {
//            $('#content').hide();
            $('#admin-editor').show();
            //$('#admin-preview').show();
            $('#filename').val( resp["page"]["filename"] );
            $('#editor_title').val( resp["page"]["title"] );
            $('#editor_body').val( resp["page"]["body"] );
            $('#editor_body').keyup();    // update preview
            //$('#editor_body').html(resp);
       });
       return false;
   });

    $('#cancel').click(function(){
        $('#editor_title').val('');
        $('#editor_body').val('');
        //$('#content').show();
        $('#content').html(original_content);
        original_content = '';
        $('#admin-editor').hide();
        //$('#admin-preview').hide();
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


    $('.logout').click(function(){
        var url = '/_dwimmer/logout.json';
        $.get(url, function(resp) {
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


    $(".list_users").click(function(){
        manage_bar();
        $.getJSON('/_dwimmer/list_users.json', function(resp) {
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

    $(".add_user").click(function(){
        //alert("TODO: add user");
        manage_bar();
        $('#manage-add-user').show();
        return false;
    });
    $("#add-user-form").submit(function() {
     // var url = $(this).attr('action') + '?' + $(this).serialize();
        var url = "/_dwimmer/add_user.json";
        $.post(url, $(this).serialize(), function(resp) {
            if (resp["success"] == 1) {
                alert('added');
            } else {
                alert(resp["error"]);
            }
        }, 'json');
        return false;
     });


    $(".add_page").click(function(){
        alert("TODO: add page");
        // resize the managemen bar (or add another bar?)
        return false;
    });

    $(".list_pages").click(function(){
        manage_bar();
        $.getJSON('/_dwimmer/get_pages.json', function(resp) {
            var html = '<ul>';
            for(var i=0; i < resp["rows"].length; i++) {
               html += '<li><a href="' + resp["rows"][i]["filename"]  + '">' + resp["rows"][i]["title"] + '</li>';
            }
            html += '</ul>';
            $('#manage-display').show();
            $('#manage-display').html(html);
        });

        return false;
    });


    $("form.login").submit(function() {
     // var url = $(this).attr('action') + '?' + $(this).serialize();
        var url = "/_dwimmer/login.json";
        $.post(url, $(this).serialize(), function(resp) {
            if (resp["success"] == 1) {
                // TODO update the username, userid in the browser, should come with the success response
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

      $(".topnav").dropDownPanels({
	speed: 250,
	resetTimer: 500
      });

      $(".close_manage_bar").click(function(){
//        alert("TODO save changes made or alert if not yet saved?");
          $('#manage-display').empty();
          $('#manage-bar').hide();
          return false;
     });
});

function get_and_show_user (value) {
    $.getJSON('/_dwimmer/get_user.json?id=' + value, function(resp) {
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

function send_query() {
            var query = $('#query').val();
            //alert($('#what').val());
            var what = $('#what').val();
            $('#result').html('Searching ...');
            $.get('/q/' + query + '/' + what, function(resp) {
                    $('#content').hide();
                    if (resp["error"]) {
                       alert(resp["error"]);
                    } else {
//alert(resp);
//                     $('#result').html('ok');
                       var html = '';
                       var data = resp["data"];
                       for (var i=0; i<data.length; i++) {
                           // distribution
                           if (data[i]["distribution"] == '1') {
                                html += '<div class="author"><a href="/id/' + data[i]["author"]   + '">' + data[i]["author"] + '</a></div>';
                                html += '<div class="name"><a href="/dist/' + data[i]["name"] + '">' + data[i]["name"]   + '</a></div>';
                                html += '<div class="version">' + data[i]["version"] + '</div>';
                           }
                           // author
                           if (data[i]["author"] == '1') {
                                var name = data[i]["asciiname"];
                                if (data[i]["name"]) {
                                        name = data[i]["name"];
                                }
                                html += '<div class="name"><a href="/id/' + data[i]["pauseid"] + '">' + data[i]["pauseid"] + '(' + name + ')' + '</a></div>';
                                if (data[i]["homepage"]) {
                                        html += '<div class="name"><a href="' + data[i]["homepage"] + '">' + data[i]["homepage"]   + '</a></div>';
                                }
                           }
                          
                           html += '<br>';
                       }
                       $('#result').html(html);
                    }
                    if (resp["ellapsed_time"]) {
                        $('#ellapsed_time').html("Ellapsed time: " + resp.ellapsed_time);
                    }
            }, 'json');
            return false;
};

