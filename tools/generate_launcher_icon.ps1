Add-Type -AssemblyName System.Drawing
$res = Join-Path $PSScriptRoot '..\android\app\src\main\res'
function Brush($hex) { [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($hex)) }
function Rounded($x,$y,$w,$h,$r) {
 $p=[Drawing.Drawing2D.GraphicsPath]::new()
 $p.AddArc($x,$y,2*$r,2*$r,180,90); $p.AddArc($x+$w-2*$r,$y,2*$r,2*$r,270,90)
 $p.AddArc($x+$w-2*$r,$y+$h-2*$r,2*$r,2*$r,0,90); $p.AddArc($x,$y+$h-2*$r,2*$r,2*$r,90,90); $p.CloseFigure(); $p
}
function Draw-Icon($file,$size,$layer) {
 $b=[Drawing.Bitmap]::new($size,$size); $g=[Drawing.Graphics]::FromImage($b)
 $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
 if ($layer -eq 'foreground') {$g.ScaleTransform($size/108,$size/108)}
 else {
  $g.ScaleTransform($size/72,$size/72); $g.TranslateTransform(-18,-18)
  $clip=Rounded 18 18 72 72 20; $g.SetClip($clip)
  $gradient=[Drawing.Drawing2D.LinearGradientBrush]::new([Drawing.Rectangle]::new(0,0,108,108),[Drawing.ColorTranslator]::FromHtml('#28A970'),[Drawing.ColorTranslator]::FromHtml('#134638'),45.0)
  $g.FillRectangle($gradient,0,0,108,108); $gradient.Dispose()
 }
 $g.FillEllipse((Brush '#C6FF85'),50,27,8,8)
 $g.FillRectangle((Brush '#C6FF85'),52,33,4,10)
 $g.FillPath((Brush '#163E35'),(Rounded 30 42 48 35 13))
 $g.FillPath((Brush '#F4FFF1'),(Rounded 29 38 50 35 13))
 $g.FillPath((Brush '#D5F5E3'),(Rounded 33 43 42 23 10))
 $pen=[Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#205D48'),3)
 $pen.StartCap=[Drawing.Drawing2D.LineCap]::Round; $pen.EndCap=$pen.StartCap; $pen.LineJoin=[Drawing.Drawing2D.LineJoin]::Round
 $g.DrawLines($pen,[Drawing.Point[]]@([Drawing.Point]::new(45,49),[Drawing.Point]::new(40,54),[Drawing.Point]::new(45,59)))
 $g.DrawLines($pen,[Drawing.Point[]]@([Drawing.Point]::new(63,49),[Drawing.Point]::new(68,54),[Drawing.Point]::new(63,59)))
 $g.DrawLine($pen,56,48,52,60); $pen.Dispose()
 $g.Dispose(); $b.Save($file,[Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
}
foreach($entry in @{mdpi=48;hdpi=72;xhdpi=96;xxhdpi=144;xxxhdpi=192}.GetEnumerator()){
 Draw-Icon (Join-Path $res "mipmap-$($entry.Key)\ic_launcher.png") $entry.Value 'legacy'
}
$drawable=Join-Path $res 'drawable-xxxhdpi'
New-Item -ItemType Directory -Force $drawable | Out-Null
Draw-Icon (Join-Path $drawable 'learncodz_launcher_foreground.png') 432 'foreground'
Draw-Icon (Join-Path $PSScriptRoot '..\deliverables\LearnCodz-icon-preview.png') 512 'legacy'
