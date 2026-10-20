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
    mt: "maintain",
    cl: "clear",
    ex: "exit",
    sc: "scoop",
    py: "python",

    dli: "download img",
    dlt: "download trk",
    dlv: "download vid",
    dla: "download arc",
    plv: "play vid",
    pla: "play aud",
    slh: "split horz",
    slv: "split vert"
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

let command = "cd utilities; uv run yt-dlp --merge-output-format mp4 --paths ../downloads/videos"
let options = "--output '%(title)s [%(id)s] (%(section_start)s-%(section_end)s).%(ext)s' --force-keyframes-at-cuts"
def trim [link, time] {[$command, $options, "--download-sections", $time, $link] | str join " " | nu -c $in}

def download [type, ...links] {
    let workspace = $env.WORKSPACE_ROOT

    let images = ($workspace | path join "downloads" "images")
    let tracks = ($workspace | path join "downloads" "tracks")
    let videos = ($workspace | path join "downloads" "videos")

    let cookies = ($workspace | path join "utilities" "cookies.txt")
    let ytdlp = ($workspace | path join "configs" "yt-dlp.conf")

    for $link in $links {
        let args = match $type {
            "img" => {["gallery-dl" "--cookies" $cookies "--directory" $images $link]}
            "trk" => {["spotdl" "--cookie-file" $cookies "--output" $tracks $link]}
            "vid" => {["yt-dlp" "--merge-output-format" "mp4" "--paths" $videos $link]}
            "arc" => {["yt-dlp" "--config-location" $ytdlp $link]}
            _ => {error make {msg: $"Unsupported download: ($type)"}}
        }

        uv run --directory ($workspace | path join "utilities") ...$args
    }
}

def play [type, link] {
    let workspace = $env.WORKSPACE_ROOT

    let utilities = ($workspace | path join "utilities" ".venv")
    let ytdlp = ($utilities | path join "Scripts" "yt-dlp.exe")

    let args = match $type {
        "vid" => ["--fullscreen" "--taskbar-progress=no"]
        "aud" => ["--no-video" "--taskbar-progress=no"]
        _ => {error make {msg: $"Unsupported playback: ($type)"}}
    }

    mpv --msg-level=demux=fatal,ffmpeg=no,lavf=no $"--script-opts=ytdl_hook-ytdl_path=($ytdlp)" $link ...$args
}

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
