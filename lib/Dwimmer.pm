package Dwimmer;
use Dancer ':syntax';

use File::Slurp qw(read_file write_file);

our $VERSION = '0.01';

get '/' => sub {
    my $filename = config->{dwimmer}{json};
    my $json = -e $filename ? read_file $filename : '{}';
    my $data = from_json $json;
    template 'index', {data => $data};
};


get '/page' => sub {
    template 'page';
};

post '/page' =>  sub {
    my $filename = config->{dwimmer}{json};
    my $json = -e $filename ? read_file $filename : '{}';
    my $data = from_json $json;
    my $now   = time;
    $data->{$now} = {
        title => params->{title},
        text  => params->{text},
    };

    write_file $filename, to_json($data);
    redirect '/';
};

true;
