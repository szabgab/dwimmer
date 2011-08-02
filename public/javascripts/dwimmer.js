 $(document).ready(function() {
   $('#editor').hide();
   $('#preview').hide();
   $('#content').show();
    
   $(".edit_this_page").click(function() {
       //$(location).attr('pathname');
       //window.location.pathname;
       var url = $(location).attr('href');
       $.get(url, function(resp) {
            $('#content').hide();
            $('#editor').show();
            $('#preview').show();
            //$('#formtitle').value = 'ddd';
            $('#text').html('www'); //resp["title"]);
            //$('#text').html(resp);
            alert(resp);
       });
              
       // fill editor with content fetched from the server
       // update preview
   });

    $('#cancel').click(function(){
        $('#content').show();
        $('#editor').hide();
        $('#preview').hide();
        return false;
    });
    
    $('#sbmt').click(function(){
       //alert("xxx");
       var text = $('#text').val();
       //alert(text);
       //$('#preview').html(text);
    });

    $('#text').keyup(function(){
        var text = $('#text').val();
        var html = markup(text);
        $('#preview').html(html);
    });
});




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

