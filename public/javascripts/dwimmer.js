var username;
var userid;

 $(document).ready(function() {
   $('#editor').hide();
   $('#preview').hide();
   $('#content').show();
   $('#logged_in_bar').hide();
   $('#guest_bar').hide();
   $('#manage-bar').hide();
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
       var url = $(location).attr('href') + '?content_type=json';
       $.getJSON(url, function(resp) {
            $('#content').hide();
            $('#editor').show();
            $('#preview').show();
            $('#formtitle').val( resp["page"]["title"] );
            $('#text').val( resp["page"]["body"] );
            $('#text').keyup();    // update preview
            //$('#text').html(resp);
       });
       return false;
   });

    $('#cancel').click(function(){
        $('#formtitle').val('');
        $('#text').val('');
        $('#content').show();
        $('#editor').hide();
        $('#preview').hide();

        return false;
    });

    $('#save').click(function(){
       var text = $('#text').val();
       var title = $('#formtitle').val();

        var url = '/_dwimmer/save';
        var data = $("#frm").serialize();
//        alert(data);
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

    $('#text').keyup(function(){
        var text = $('#text').val();
        var html = markup(text);
        $('#preview').html(html);
    });


    $('.logout').click(function(){
        var url = '/_dwimmer/logout.json';
        $.get(url, function(resp) {
            $("#logged-in").html('');
             $('#logged_in_bar').hide();
             $('#guest_bar').show();
        });
        return false;
    });


    $(".manage").click(function(){
        // TODO do something here?
        return false;
    });

    $(".show_user").click(function(){
        alert("TODO: show_user");
    });

    $(".list_users").click(function(){
        $('#manage-bar').show();
        $.getJSON('/_dwimmer/list_users.json', function(resp) {
            add_close();
            var html = '<ul>';
            for(var i=0; i < resp["users"].length; i++) {
               html += '<li><a href="" value="' + resp["users"][i]["id"]  + '">' + resp["users"][i]["name"] + '</li>';
            }
            html += '</ul>';
            $('#manage-bar').append(html);
            
            // Setup the events only after the html was appended!
            $('#manage-bar  a[value!="close"]').click(function() {
                var value = $(this).attr('value');
                //alert(value); // TODO fetch the user info of this id.
                $.getJSON('/_dwimmer/get_user.json?id=' + value, function(resp) {
                    $('#manage-bar').empty();
                    add_close();
                    var html = '<ul>';
                    html += '<li>id = ' + resp["id"] + '</li>';
                    html += '<li>name = ' + resp["name"] + '</li>';
                    html += '<li>fname = ' + resp["fname"] + '</li>';
                    html += '<li>lname = ' + resp["lname"] + '</li>';
                    html += '<li>email = ' + resp["email"] + '</li>';
                    html += '<li>verified = ' + resp["verified"] + '</li>';
                    html += '<li>register_ts = ' + resp["register_ts"] + '</li>';
                    html += '</ul>';
                    $('#manage-bar').append(html);
                });
                return false;
            });
        });

        //alert("TODO: list users");
        return false;
    });
    $(".add_user").click(function(){
        alert("TODO: add user");
        // resize the managemen bar (or add another bar?)
        return false;
    });
    $(".add_page").click(function(){
        alert("TODO: add page");
        // resize the managemen bar (or add another bar?)
        return false;
    });
    $(".list_pages").click(function(){
        alert("TODO: list pages");
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
         alert('TODO: show user details');
         // get data of current user
         // enlarge the admin area
         // display the user info for now, later the user admin form
         return false;
      });

      $(".topnav").dropDownPanels({
	speed: 250,
	resetTimer: 1000
      });

});

function add_close() {
    var html = '<a class="close_manage_bar" href="" value="close">close</a><br>';
    $('#manage-bar').append(html);

    $(".close_manage_bar").click(function(){
//        alert("TODO save changes made or alert if not yet saved?");
        $('#manage-bar').empty();
        $('#manage-bar').hide();
        $
        return false;
    });
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

