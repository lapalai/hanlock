<# Renders the simple rect/path SVG mark to PNG and a multi-resolution Windows ICO. #>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore, WindowsBase
$assets = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\assets'))
[xml]$svg = [IO.File]::ReadAllText((Join-Path $assets 'hanlock.svg'))
$rect = $svg.SelectSingleNode("//*[local-name()='rect']")
$group = $svg.SelectSingleNode("//*[local-name()='g']")
$paths = $svg.SelectNodes("//*[local-name()='path']")
$brushes = New-Object Windows.Media.BrushConverter
$sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
$images = @()
foreach ($size in $sizes) {
    $visual = New-Object Windows.Media.DrawingVisual
    $context = $visual.RenderOpen()
    try {
        $context.PushTransform((New-Object Windows.Media.ScaleTransform(($size / 64.0), ($size / 64.0))))
        $box = New-Object Windows.Rect([double]$rect.x, [double]$rect.y, [double]$rect.width, [double]$rect.height)
        $context.DrawRoundedRectangle($brushes.ConvertFromString($rect.fill), $null, $box, [double]$rect.rx, [double]$rect.rx)
        foreach ($path in $paths) {
            $pen = New-Object Windows.Media.Pen($brushes.ConvertFromString($path.stroke), [double]$group.GetAttribute('stroke-width'))
            $pen.StartLineCap = [Windows.Media.PenLineCap]::Round
            $pen.EndLineCap = [Windows.Media.PenLineCap]::Round
            $pen.LineJoin = [Windows.Media.PenLineJoin]::Round
            $context.DrawGeometry($null, $pen, [Windows.Media.Geometry]::Parse($path.d))
        }
        $context.Pop()
    } finally {
        $context.Close()
    }
    $bitmap = New-Object Windows.Media.Imaging.RenderTargetBitmap($size, $size, 96, 96, [Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($visual)
    $encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream = New-Object IO.MemoryStream
    try {
        $encoder.Save($stream)
        $png = $stream.ToArray()
        $images += ,$png
        if ($size -eq 256) { [IO.File]::WriteAllBytes((Join-Path $assets 'hanlock.png'), $png) }
    } finally {
        $stream.Dispose()
    }
}
$stream = [IO.File]::Create((Join-Path $assets 'hanlock.ico'))
$writer = New-Object IO.BinaryWriter($stream)
try {
    $writer.Write([UInt16]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
        $writer.Write([byte]$dimension)
        $writer.Write([byte]$dimension)
        $writer.Write([UInt16]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]32)
        $writer.Write([UInt32]$images[$i].Length)
        $writer.Write([UInt32]$offset)
        $offset += $images[$i].Length
    }
    foreach ($png in $images) { $writer.Write([byte[]]$png) }
} finally {
    $writer.Dispose()
}
Write-Host 'Generated assets/hanlock.ico (16-256px) and assets/hanlock.png from SVG.'
