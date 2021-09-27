
REM if "%~1" == "" goto :EOF

set "tool=C:\Program Files\ImageMagick-7.1.0-Q16-HDRI\"
set "inputfolder=C:\Users\GGPC\Desktop\res\"
set "outputfolder="C:\Users\GGPC\Desktop\res\"

cd %tool%

magick.exe  montage %inputfolder%door_000[0-9].png -mode Concatenate  -background none -tile 3x %outputfolder%001_3frames.png 

magick.exe  montage %inputfolder%sheep_000[0-9].png %inputfolder%slime_000[0-9].png %inputfolder%water_000[0-9].png %inputfolder%crystal_ore_000[0-9].png -mode Concatenate  -background none -tile 2x %outputfolder%002_2frames.png 

magick.exe  montage %inputfolder%slimeking_000[0-9].png -mode Concatenate  -background none -tile 2x %outputfolder%003_boss.png 

magick.exe  montage %inputfolder%others_000[0-9].png -mode Concatenate  -background none -tile 1x %outputfolder%004_others.png 

magick.exe  montage %inputfolder%player_blue_000[0-9].png %inputfolder%player_blue_s_000[0-9].png %inputfolder%player_yellow_000[0-9].png %inputfolder%player_yellow_s_000[0-9].png -mode Concatenate  -background none -tile 5x %outputfolder%005_player.png 