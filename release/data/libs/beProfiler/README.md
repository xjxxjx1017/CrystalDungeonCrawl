# Vignette

**Title**:
lua-profiler

**Version**:
1.1

**Description**:
Code profiling for Lua based code;
The output is a report file (text) and optionally to a console or other logger.

The initial reason for this project was to reduce  misinterpretations of code profiling
caused by the lengthy measurement time of the 'ProFi' profiler v1.3;
and then to remove the self-profiler functions from the output report.

The profiler code has been substantially rewritten to remove dependence to the 'OO'
class definitions, and repetitions in code;
thus this profiler has a smaller code footprint and reduced execution time up to ~900% faster.

The second purpose was to allow slight customisation of the output report,
which I have parametrised the output report and rewritten.

Caveats: I didn't include an 'inspection' function that ProFi had, also the RAM
output is gone. Please configure the profiler output in top of the code, particularly the
location of the profiler source file (if not in the 'main' root source directory).


**Authors**:
Charles Mallah

**Copyright**:
(c) 2018-2020 Charles Mallah

**License**:
MIT license

**Sample**:
Output will be generated like this, all output here is ordered by time:

    > TOTAL TIME   = 0.030000 s
    --------------------------------------------------------------------------------------
    | FILE                : FUNCTION                    : LINE   : TIME   : %     : #    |
    --------------------------------------------------------------------------------------
    | map                 : new                         :   301  : 0.1330 : 52.2  :    2 |
    | map                 : unpackTileLayer             :   197  : 0.0970 : 38.0  :   36 |
    | engine              : loadAtlas                   :   512  : 0.0780 : 30.6  :    1 |
    | map                 : init                        :   292  : 0.0780 : 30.6  :    1 |
    | map                 : setTile                     :    38  : 0.0500 : 19.6  : 20963|
    | engine              : new                         :   157  : 0.0220 : 8.6   :    1 |
    | map                 : unpackObjectLayer           :   281  : 0.0190 : 7.5   :    2 |
    --------------------------------------------------------------------------------------
    | ui                  : sizeCharLimit               :   328  : ~      : ~     :    2 |
    | modules/profiler    : stop                        :   192  : ~      : ~     :    1 |
    | ui                  : sizeWidthToScreenWidthHalf  :   301  : ~      : ~     :    4 |
    | map                 : setRectGridTo               :   255  : ~      : ~     :    7 |
    | ui                  : sizeWidthToScreenWidth      :   295  : ~      : ~     :   11 |
    | character           : warp                        :    32  : ~      : ~     :   15 |
    | panels              : Anon                        :     0  : ~      : ~     :    1 |
    --------------------------------------------------------------------------------------

The partition splits the notable code that is running the slowest, all other code is running
too fast to determine anything specific, instead of displaying "0.0000" the script will tidy
this up as "~". Table headers % and # refer to percentage total time, and function call count.


**Example**:
Print a profile report of a code block

    local profiler = require("profiler")
    profiler.start()
    -- Code block and/or called functions to profile --
    profiler.stop()
    profiler.report("profiler.log")


**Example**:
Profile a code block and allow mirror print to a custom print function

    local profiler = require("profiler")
    function exampleConsolePrint()
      -- Custom function in your code-base to print to file or console --
    end
    profiler.attachPrintFunction(exampleConsolePrint, true)
    profiler.start()
    -- Code block and/or called functions to profile --
    profiler.stop()
    profiler.report("profiler.log") -- exampleConsolePrint will now be called from this


**Example**:
Override a configuration parameter programmatically; insert your override values into a
new table using the matched key names:

    local overrides = {
                        fW = 100, -- Change the file column to 100 characters (from 20)
                        fnW = 120, -- Change the function column to 120 characters (from 28)
                      }
    profiler.configuration(overrides)


# API

**attachPrintFunction** (fn, verbose\*)  

> Attach a print function to the profiler, to receive a single string parameter  
> &rarr; **fn** (function) <*required*>  
> &rarr; **verbose** (boolean) <*default: false*>  

**start**
> Start the profiling  

**stop**
> Stop profiling  

**report** (filename\*)  

> Writes the profile report to file (will stop profiling if not stopped already)  
> &rarr; **filename** (string) <*default: "profiler.log"*> `File will be created and overwritten`  

**configuration** (overrides)  

> Modify the configuration of this module programmatically;  
> &rarr; **overrides** (table) <*required*> `Each key is from a valid name, the value is the override`  
> - outputFile = "profiler.lua" `Name of this profiler (to remove itself from reports)`  
> - emptyToThis = "~" `Rows with no time are set to this value`  
> - fW = 20 `Width of the file column`  
> - fnW = 28 `Width of the function name column`  
> - lW = 7 `Width of the line column`  
> - tW = 7 `Width of the time taken column`  
> - rW = 6 `Width of the relative percentage column`  
> - cW = 5 `Width of the call count column`  
> - reportSaved = "> Report saved to: " `Text for the file output confirmation`  

# Project

+ [Back to root](README.md)