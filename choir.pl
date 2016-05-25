use strict;
use warnings;
use Config;
use 5.14.1;
use Data::Dumper;

my $text=<<TXT;
Froiday shooner gutter funkun tokhter ous elusium
TXT

if ($Config{osname} ne 'darwin') {
    say "Froi-day shooner gutter-funkun tokh-ter ous elusium";
    exit;
}

my $output = `say -v?`;
my @rows = split /\n/, $output;
my @en_voices;

# get just the english voices
foreach my $row (@rows) {
    my @columns = split /\s\s+/, $row;
    push @en_voices, $columns[0] if $columns[1] =~ /\Aen[_|-]/; #for some reason apple uses en-scotland for the scottish voice
}

# make them sing
foreach my $voice (@en_voices) {
    print "Recording $voice..";
    if (-f "/tmp/$voice.aiff") {
        unlink("/tmp/$voice.aiff");
    }
    my $command = qq|say -v "$voice" -o "/tmp/$voice" "$text"|;
    # say $command;
    `$command`;
    say ".done!";
}

# calculate the file size - we'll use it as a proxy for the file's
# duration. for this to work well, we need all sounds to be of roughly
# the same size, so we'll discard any voice that is > 20% the minimum
# size

my %voice_sizes;
foreach my $voice (@en_voices) {
    my $file = "/tmp/$voice.aiff";
    if (-f $file) {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks)
            = stat($file);
        $voice_sizes{$voice} = $size;
    }
}

# say Dumper(\%voice_sizes);
my $min = min(values %voice_sizes);
my $threshold = int($min + 0.20*$min);

say "Minimum file size: $min bytes";
say "Going to find voices within 20% of this size, i.e. < $threshold bytes";
my @usable_voices =  grep { $_ if ($voice_sizes{$_} <= $threshold && $voice_sizes{$_} > $min) } sort keys %voice_sizes;
say "Going to use the following ${\($#usable_voices+1)} voices:";
say join "\n", @usable_voices;
print "Generating choir..";

my $ffmpeg = "~/Dropbox/bin/ffmpeg ";
my $ffmpeg_opts = "";
foreach my $voice (@usable_voices) {
    $ffmpeg_opts .= qq|-i "/tmp/$voice.aiff" |;
}

$ffmpeg_opts .= "-filter_complex amix=inputs=${\($#usable_voices+1)}:duration=longest:dropout_transition=3 /tmp/choir.aiff";
my $command = "$ffmpeg $ffmpeg_opts";
# say $command;
if (-f "/tmp/choir.aiff") {
    unlink("/tmp/choir.aiff");
}
`$command &>/dev/null`;
say ".done!";
say "Please open /tmp/choir.aiff to listen to the choir!";

sub min {
    my $min = $_[0];
    for (@_) {
        if ($_ < $min) { $min = $_; }
    }
    return $min;
}
