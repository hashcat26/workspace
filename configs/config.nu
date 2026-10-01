# CONFIGURATION OVERRIDES
source $"($nu.cache-dir)/carapace.nu"

$env.config.show_banner = "none"
$env.config.buffer_editor = "notepad"

$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true

$env.config.footer_mode = "auto"
$env.config.table.missing_value_symbol = "---"

$env.config.rm.always_trash = true
$env.config.use_kitty_protocol = true
$env.config.shell_integration.osc133 = false

$env.config.filesize.precision = 2

$env.config.abbreviations = {
    ls: "ls -s",
    la: "ls -a",
    ll: "ls -al",
    lr: "ls -a **/*",
    cl: "clear",
    sc: "scoop",
    py: "python"
}


# ADDITIONAL COMMANDS
use std null-device

alias workspace = cd ../workspace
alias bucket = cd ../bucket
alias activate = overlay use utilities/.venv/Scripts/activate.nu
alias maintain = powershell ./workspace.ps1
alias list = scoop list

def clean [] {scoop cache rm --all; scoop cleanup --all}
def install [...apps] {for $app in $apps {scoop install $app}}
def remove [...apps] {for $app in $apps {scoop uninstall --purge $app}}
def fetch [...files] {for $file in $files {aria2c --conf-path configs/aria2.conf $file}}

def img [link] {cd utilities; uv run gallery-dl --cookies cookies.txt --directory ../downloads/images $link}
def trk [link] {cd utilities; uv run spotdl --cookie-file cookies.txt --output ../downloads/tracks $link}
def vid [link] {cd utilities; uv run yt-dlp --merge-output-format mp4 --paths ../downloads/videos $link}
def arc [link] {cd utilities; uv run yt-dlp --config-location ../configs/yt-dlp.conf $link}

def image [...links] {for $link in $links {img $link}}
def track [...links] {for $link in $links {trk $link}}
def video [...links] {for $link in $links {vid $link}}
def archive [...links] {for $link in $links {arc $link}}

alias play = ffplay -fs -autoexit -infbuf -framedrop -hide_banner -window_title ffplay -i -
def listen [link] {cd utilities; uv run yt-dlp $link --format ba --output - err> (null-device) | play -nodisp}
def watch [link] {cd utilities; uv run yt-dlp $link --format bv+ba --output - err> (null-device) | play}
def lurk [link] {cd utilities; uv run yt-dlp $link --format ba* --output - err> (null-device) | play -nodisp}
def stream [link] {cd utilities; uv run yt-dlp $link --format bv*+ba* --output - err> (null-device) | play}

let command = "cd utilities; uv run yt-dlp --merge-output-format mp4 --paths ../downloads/videos"
let options = "--output '%(title)s [%(id)s] (%(section_start)s-%(section_end)s).%(ext)s' --force-keyframes-at-cuts"
def trim [link, time] {[$command, $options, "--download-sections", $time, $link] | str join " " | nu -c $in}

def split [orientation, ...videos] {
    let count = $videos | length

    let width = if $orientation == "horz" {1920 / $count} else {1920}
    let height = if $orientation == "vert" {1080 / $count} else {1080}
    let stack = if $orientation == "horz" {"hstack"} else {"vstack"}

    let size = $"($width):($height)"
    let cover = $"scale=($size):force_original_aspect_ratio=increase,crop=($size)"

    let transforms = $videos
        | enumerate
        | each {|video| $"[vid($video.index + 1)]($cover)[sv($video.index + 1)]"}

    let inputs = 1..$count
        | each {|index| $"[sv($index)]"}
        | str join ""

    let filter = $transforms
        | append $"($inputs)($stack)=inputs=($count):shortest=1,setsar=1[vo]"
        | str join ";"

    let external = $videos
        | skip 1
        | each {|video| $"--external-file=($video)"}

    mpv --fullscreen --loop --msg-level=ffmpeg/video=error $"--lavfi-complex=($filter)" $videos.0 ...$external
}

def convert [input, output] {
    let input_ext = ($input | path parse).extension | str lowercase
    let output_ext = ($output | path parse).extension | str lowercase

    let image = ["png" "jpg" "jpeg" "webp" "gif" "bmp" "tif" "tiff" "avif" "heic" "ico"]
    let audio = ["mp3" "wav" "flac" "aac" "m4a" "ogg" "opus" "wma"]
    let video = ["mp4" "mkv" "webm" "mov" "avi" "wmv" "flv" "m4v" "ts"]
    let vector = ["svg" "eps"]
    let document = ["pdf"]
    let diagram = ["drawio"]

    let type = {|ext|
        if $ext in $image {
            "image"
        } else if $ext in $audio {
            "audio"
        } else if $ext in $video {
            "video"
        } else if $ext in $vector {
            "vector"
        } else if $ext in $document {
            "document"
        } else if $ext in $diagram {
            "diagram"
        } else {
            error make $"Unsupported format: .($ext)"
        }
    }

    let input_type = do $type $input_ext
    let output_type = do $type $output_ext

    if $input_ext == $output_ext {
        cp $input $output
    } else if $input_type in ["audio" "video"] and $output_type in ["audio" "video"] {
        ffmpeg -i $input $output
    } else if $input_type in ["image" "document"] and $output_type in ["image" "document"] {
        magick $input $output
    } else if $input_type == "vector" and $output_type in ["image" "vector" "document"] {
        inkscape $input --export-filename $output
    } else if $input_type == "diagram" and $output_type in ["image" "vector" "document"] {
        drawio --export $input --output $output
    } else {
        error make $"Unsupported conversion: .($input_ext) → .($output_ext)"
    }
}
