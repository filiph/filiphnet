<?php

$down_files = array(
	"./exercise 7.mp3", /* 0 */
	"./demo_june2006.mp3", 
	"./Philip Age - March 2009 Promo (320kbps).mp3", 
	"./Philip Age - Deadmau5 Best Of Mix (320kbps).mp3", 
	"./Philip Age - Summer of 2009 (HQ).mp3", 
	"philip age - chill out astronaut (128 CBR).mp3", 
	"Philip Age - Summer of 2009 (320kbps).mp3", 
	"./781439_Anjunadeep_01__Part_1__Continuous_DJ_Mix.mp3", 
	"./781440_Anjunadeep_01__Part_2__Continuous_DJ_Mix.mp3",
	"./Philip Age - Magnet (160kbps).mp3",
	"./Philip Age - Magnet (hifi).mp3", /* 10 */
	"./Philip Age - Comment tu fais.mp3",
	"./Philip Age - Monster (continuous mix).mp3",
	"./Blending Remix - ver3.wav",
	"./Philip Age - Mono (March 2010).mp3",
	"./Philip Age - Dave Seaman Tribute Set [Aug 2010].mp3",
	"./Philip Age - What Others Receive.mp3",
	"./Philip Age - DJ's Mate Mix.mp3",
	"./Philip Age - Apollo (hq).mp3",
  "./Philip Age - Harvest.mp3" /* 19 */
	);

$filename = $down_files[$_GET['file']];

// required for IE, otherwise Content-disposition is ignored
if(ini_get('zlib.output_compression'))
  ini_set('zlib.output_compression', 'Off');

// addition by Jorg Weske
$file_extension = strtolower(substr(strrchr($filename,"."),1));

if( $filename == "" ) 
{
  echo "<html><title>Download Script</title><body>ERROR: you have to specify the download file. If you're lost, <a href="/">go to the homepage</a>.</body></html>";
  exit;
} elseif ( ! file_exists( $filename ) ) 
{
  echo "<html><title>Download Script</title><body>ERROR: File not found. If you're lost, <a href='/'>go to the homepage</a>.</body></html>";
  exit;
};
switch( $file_extension )
{
  case "pdf": $ctype="application/pdf"; break;
  case "exe": $ctype="application/octet-stream"; break;
  case "zip": $ctype="application/zip"; break;
  case "doc": $ctype="application/msword"; break;
  case "xls": $ctype="application/vnd.ms-excel"; break;
  case "ppt": $ctype="application/vnd.ms-powerpoint"; break;
  case "gif": $ctype="image/gif"; break;
  case "png": $ctype="image/png"; break;
  case "jpeg":
  case "jpg": $ctype="image/jpg"; break;
  default: $ctype="application/force-download";
}
header("Pragma: public"); // required
header("Expires: 0");
header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
header("Cache-Control: private",false); // required for certain browsers 
header("Content-Type: $ctype");
// change, added quotes to allow spaces in filenames, by Rajkumar Singh
header("Content-Disposition: attachment; filename=\"".basename($filename)."\";" );
header("Content-Transfer-Encoding: binary");
header("Content-Length: ".filesize($filename));
readfile("$filename");
exit();

?>
