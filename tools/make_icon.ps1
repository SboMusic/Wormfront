param()
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskImage=[Drawing.Image]::FromFile((Join-Path $taskRoot 'assets/icon.png'))
$taskFrames=@()
try {
 foreach($taskSize in @(16,32,48,64,128,256)) {
  $taskBitmap=[Drawing.Bitmap]::new($taskSize,$taskSize)
  $taskGraphics=[Drawing.Graphics]::FromImage($taskBitmap)
  $taskGraphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $taskGraphics.DrawImage($taskImage,0,0,$taskSize,$taskSize)
  $taskStream=[IO.MemoryStream]::new()
  $taskBitmap.Save($taskStream,[Drawing.Imaging.ImageFormat]::Png)
  $taskFrames+=,@{size=$taskSize;bytes=$taskStream.ToArray()}
  $taskGraphics.Dispose();$taskBitmap.Dispose();$taskStream.Dispose()
 }
 $taskOutput=[IO.File]::Create((Join-Path $taskRoot 'assets/icon.ico'))
 $taskWriter=[IO.BinaryWriter]::new($taskOutput)
 try {
  $taskWriter.Write([uint16]0);$taskWriter.Write([uint16]1);$taskWriter.Write([uint16]$taskFrames.Count)
  $taskOffset=6+16*$taskFrames.Count
  foreach($taskFrame in $taskFrames) {
   $taskDimension=if($taskFrame.size -eq 256){0}else{$taskFrame.size}
   $taskWriter.Write([byte]$taskDimension);$taskWriter.Write([byte]$taskDimension)
   $taskWriter.Write([uint16]0);$taskWriter.Write([uint16]1);$taskWriter.Write([uint16]32)
   $taskWriter.Write([uint32]$taskFrame.bytes.Length);$taskWriter.Write([uint32]$taskOffset)
   $taskOffset+=$taskFrame.bytes.Length
  }
  foreach($taskFrame in $taskFrames){$taskWriter.Write([byte[]]$taskFrame.bytes)}
 } finally {$taskWriter.Dispose();$taskOutput.Dispose()}
} finally {$taskImage.Dispose()}
Write-Output 'Icona Windows creata: assets/icon.ico (16-256 px).'
