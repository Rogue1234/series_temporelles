function [result,msg] = eps2xxx(epsFile,outFormats,fullGsPath,orientation)
%EPS2XXX Converts an eps file to one or several other formats using GhostScript (GS)
%
%   [result,msg] = eps2xxx(epsFile,outFormats,fullGsPath,orientation)
%
%   - epsFile:      eps file name to be converted to outFormats
%   - outFormats:   cell array of strings of output formats (one or several formats). The
%                   following formats are supported:
%                   'pdf', 'jpeg', 'png', 'tiff'
%   - fullGsPath:   (optional) FULL GS path, including the file name, to
%                   the GS executable (on win32 it could be c:\program
%                   files\gs\gs8.14\bin\gswin32c.exe). The existence for
%                   fullGsPath will be checked for if given. On the other
%                   hand, if fullGsPath is not given or empty it defaults
%                   to 'gswin32c' for pcs and 'gs' for unix and the
%                   existence will not be checked for. But in this, latter
%                   case, GS's path must be in the system's path variable.
%   - orientation:  (optional) a flag that tells how the orientation tag in eps file should be treated
%                   just before the conversion (orientation tag is changed or even removed):
%                       0 -> no change (default)
%                       1 -> flip orientation
%                       2 -> remove orientation
%   
%   - result:       -1: errors, no file created; 0: file(s) created but
%                   there were warnings; 1: OK (no errors or warnings)
%   - msg:          resulting status on file being processed (confirmation string , error
%                   string or warning string)
%
%   NOTES: GhostScript is needed for this function to work. Orientation can
%   also be changed - use this only if you have problems with the orientation - in
%   such a case try with orientation=1 first and then orientation=2 if the first option is
%   not the right one.
%
%   EPS2XXX converts an existing EPS file to several other formats using
%   Ghostscript. EPS2XXX reads an eps file, modifies the bounding box and creates the output
%   files whose sizes are determined by the bounding box and not by the paper size. This can not be
%   accomplished by using Ghostscript only. So, all that one needs is of course
%   Matlab and Ghostscript drivers. If bounding box and/or orientation
%   cannot be found a warning message is raised but the output IS created.
% 
%   This tool is especially suited for LaTeX (TeX) users who want to create pdf
%   documents on the fly (by including pdf graphics and using either pdftex or
%   pdflatex). An example would be, if you are using LaTeX (TeX) to typeset
%   documents then the usual (simple) way to include graphics is to include eps
%   graphics using for example (if there exists myfigure.eps)
%   \begin{figure}
%       \centering
%       \includegraphics[scale=0.8]{myfigure}\\
%       \caption{some caption.}
%   \end{figure}
%   To use pdflatex (pdftex) you do not need to change anything but provide another
%   file myfigure.pdf in the same directory along with myfigure.eps. And this file,
%   of course, can be generated by EPS2PDF.
%
%   This function was tested on win32 system running Matlab R13sp1. It should work
%   on all platforms, if not, contact the author.
%
%   EXAMPLE: Suppose there exists an eps picture with the bounding box so
%   we can create pdf, jpg, png, and tiff formats of this picture with one
%   function call as
%       eps2xxx('picture.eps',{'pdf','jpeg','png','tiff'});
%
%   SOURCE:     This is a generalization of the EPS2PDF function at which the
%               original idea came from the "eps-to-pdf" converter written
%               in Perl by Sebastian Rahtz.
%
%   See also: EPS2PDF (obsolete)
%
%   Primoz Cermelj, 28.01.2005
%   (c) Primoz Cermelj, primoz.cermelj@email.si
%
%   Version: 0.9.2
%   Last revision: 20.02.2005
%--------------------------------------------------------------------------

%----------------
% EPS2XXX history
%----------------
% [0.9.2] 17.02.2005
% - FIX:    minor bug removed
% - NEW:    the meaning of the result output parameter has changed (-1=error,
%           0=warning, 1=OK) as a result of supporting files without the
%           bounding box
%----------------

global epsFileContent

if ispc
    DEF_GS_PATH = 'gswin32c.exe';
elseif ismac
%     DEF_GS_PATH = '/sw/bin/gs';
    DEF_GS_PATH = '/usr/local/bin/gs';
elseif isunix
    DEF_GS_PATH = 'gs';
else
    DEF_GS_PATH = 'gs';
end

error(nargchk(2,5,nargin));
if nargin < 3 || isempty(fullGsPath)
    fullGsPath = DEF_GS_PATH;
else
    if ~exist(fullGsPath)
        status = ['Error: Ghostscript executable could not be found: ' fullGsPath];
        if nargout,      result = -1;    end;
        if nargout > 1,  msg = status;  else, disp(status);  end;
        return
    end
end
if nargin < 4 || isempty(orientation)
    orientation = 0;
end
orientation = abs(round(orientation));
orientation = orientation(1);
if orientation < 0 | orientation > 2
    orientation = 0;
end

nTargets = length(outFormats);
if nTargets==0 || ~iscell(outFormats)
    status = ['Error: Wrong outFormats given'];
    if nargout,      result = -1;    end;
    if nargout > 1,  msg = status;  else, disp(status);  end;
    return
end

epsFileContent = [];

% Parameters for all the formats available
GS_PARAMETERS_PDF = '-q -dNOPAUSE -dBATCH -dDOINTERPOLATE -dUseFlateCompression=true -sDEVICE=pdfwrite -r600';
GS_PARAMETERS_JPEG = '-q -dNOPAUSE -dBATCH -dDOINTERPOLATE -dUseFlateCompression=true -sDEVICE=jpeg -r300';
GS_PARAMETERS_PNG = '-q -dNOPAUSE -dBATCH -dDOINTERPOLATE -dUseFlateCompression=true -sDEVICE=png16m -r300';
GS_PARAMETERS_TIFF = '-q -dNOPAUSE -dBATCH -dDOINTERPOLATE -dUseFlateCompression=true -sDEVICE=tiffg4 -r300';

%---------
% Get file name, path
%---------
source = epsFile;
[pathstr,sourceName,ext] = fileparts(source);
if isempty(pathstr)
    pathstr = cd;
    source = fullfile(pathstr,source);
end

targetNames = outFormats;
targets = outFormats;
for ii=1:nTargets
    switch lower(outFormats{ii})
        case 'pdf'; targetNames{ii} = [sourceName '.pdf'];
        case 'jpeg'; targetNames{ii} = [sourceName '.jpg'];
        case 'png'; targetNames{ii} = [sourceName '.png'];
        case 'tiff'; targetNames{ii} = [sourceName '.tiff'];
        otherwise
            status = ['Error: wrong outFormats given'];
            if nargout,      result = -1;    end;
            if nargout > 1,  msg = status;  else, disp(status);  end;
            return
    end
    targets{ii} = fullfile(pathstr,targetNames{ii});
end

tmpFileName = sourceName;
tmpFile = fullfile(pathstr,[tmpFileName ext '.eps2xxx~']);
% tmpFileName
% Create tmp file,...
[result,errStr] = create_tmpepsfile(source,tmpFile,orientation);
if result < 0
    status = errStr;
    result = -1;
    if nargout > 1,  msg = status;  else, disp(status); end;
else
    if result == 0      % warning on bb issued
        warnMsg = errStr;
    else
        warnMsg = [];
    end
    % Run Ghostscript for each target
    for ii=1:nTargets
        switch lower(outFormats{ii})
            case 'pdf'; comandLine = ['"' fullGsPath '"' ' ' GS_PARAMETERS_PDF ' -sOutputFile=' '"' targets{ii} '"' ' -f ' '"' tmpFile '"'];
            case 'jpeg'; comandLine = ['"' fullGsPath '"' ' ' GS_PARAMETERS_JPEG ' -sOutputFile=' '"' targets{ii} '"' ' -f ' '"' tmpFile '"'];
            case 'png'; comandLine = ['"' fullGsPath '"' ' ' GS_PARAMETERS_PNG ' -sOutputFile=' '"' targets{ii} '"' ' -f ' '"' tmpFile '"'];
            case 'tiff'; comandLine = ['"' fullGsPath '"' ' ' GS_PARAMETERS_TIFF ' -sOutputFile=' '"' targets{ii} '"' ' -f ' '"' tmpFile '"'];
        end
        [stat, res] = system(comandLine);
        if stat     % error
            status = [outFormats{ii} 'Error:  failed running Ghostscript - check GS path'];
            result(ii) = -1;
            if nargout > 1,  msg{ii} = status;  else, disp(status);  end;
        else        % OK; warning may be added
            if ~isempty(warnMsg)
                status = [outFormats{ii} ' created with ' warnMsg];
                result(ii) = 0;
            else
                status = [outFormats{ii} ' successfully created'];
                result(ii) = 1;
            end
            if nargout > 1,  msg{ii} = status;  else, disp(status);  end;
        end
    end
end

% Delete tmp file
if exist(tmpFile)
    delete(tmpFile);
end






%/////////////////////////////////////////////////////////////////////
%                       SUBFUNCTIONS SECTION
%/////////////////////////////////////////////////////////////////////

%--------------------------------------------------------------------
function [status,errStr] = create_tmpepsfile(epsFile,tmpFile,orientation)
% Creates tmp eps file - file with refined content (refined bounding box and
% orientation)
global epsFileContent

status = -1;
errStr = [];
[status,errStr] = read_epsfilecontent( epsFile );
if status < 0
    return
end
[status,errStr] = update_epsfilecontent( epsFile,orientation );
if status < 0
    return
end
fh = fopen(tmpFile,'w');
if fh == -1
    status = -1;
    errStr = ['Error: temporary file cannot be created. Check write permissions.'];
    return
end
try
    fwrite(fh,epsFileContent,'char');  % fwrite is faster than fprintf
catch
    status = -1;
    errStr = ['Error: failed writing temporary file. Check write permissions.'];
end
fclose(fh);
%--------------------------------------------------------------------


%--------------------------------------------------------------------
function [status,errStr] = read_epsfilecontent( epsFile )
% Reads the content of the eps file into epsFileContent
global epsFileContent

status = -1;
errStr = [];
fh = fopen(epsFile,'r');
if fh == -1
    errStr = ['Error: file ' epsFile ' cannot be accessed or does not exist'];
    return
end
try
    epsFileContent = fread(fh,'char=>char')';       % fread is faster than fscanf
    status = 1;
catch
    status = -1;
    errStr = lasterror;
end
fclose(fh);
%--------------------------------------------------------------------


%--------------------------------------------------------------------
function [status,errStr] = update_epsfilecontent(epsFile,orientation)
% Updates eps file by adding some additional information into the header
% section concerning the bounding box (BB) if found
global epsFileContent

status = -1;
errStr = [];
bbFound = 0;

% Read current BB coordinates
ind = strfind( lower(epsFileContent), lower('%%BoundingBox:'));
if isempty(ind)
    status = 0;
    errStr = ['Warning: cannot find Bounding Box in file: ' epsFile];
else
    ii = ind(1) + 14;
    fromBB = ii;
    while ~((epsFileContent(ii) == sprintf('\n')) | (epsFileContent(ii) == sprintf('\r')) | (epsFileContent(ii) == '%'))
        ii = ii + 1;
    end
    toBB = ii - 1;
    coordsStr = epsFileContent(fromBB:toBB);
    coords = str2num( coordsStr );
    if isempty(coords) || length(coords)~=4
        status = 0;
        errStr = ['Warning: BB coordinates not found or invalid in file: ' epsFile];
    else
        bbFound = 1;
        w = abs(coords(3)-coords(1));
        h = abs(coords(4)-coords(2));
        status = 1;
    end
end

NL = getnl;

% Change the orientation if requested
changeOrientation = 0;
if orientation ~= 0
    ind = strfind( lower(epsFileContent), lower('%%Orientation:'));
    if ~isempty(ind)
        ii = ind(1) + 14;
        fromOR = ii;
        while ~((epsFileContent(ii) == sprintf('\n')) | (epsFileContent(ii) == sprintf('\r')) | (epsFileContent(ii) == '%'))
            ii = ii + 1;
        end
        toOR = ii - 1;
        orientStr = strim(epsFileContent(fromOR:toOR));
        if ~isempty(orientStr) & orientation == 1           % flip
            if strfind(lower(orientStr),'landscape')
                changeOrientation = 1;
                orientStr = 'Portrait';
            elseif strfind(lower(orientStr),'portrait')
                changeOrientation = 1;
                orientStr = 'Landscape';                
            end            
        elseif  ~isempty(orientStr) & orientation == 2      % remove
            if strfind(lower(orientStr),'landscape') | strfind(lower(orientStr),'portrait')
                changeOrientation = 1;
                orientStr = ' ';
            end
        end
    end
end

% Refine the content - add additional information and even change the
% orientation
if bbFound
    addBBContent = [' 0 0 ' int2str(w) ' ' int2str(h) ' ' NL...
        '<< /PageSize [' int2str(w) ' ' int2str(h) '] >> setpagedevice' NL...
        'gsave ' int2str(-coords(1)) ' ' int2str(-coords(2)) ' translate'];
    if changeOrientation
        if fromOR > fromBB
            epsFileContent = [epsFileContent(1:fromBB-1) addBBContent epsFileContent(toBB+1:fromOR-1) orientStr epsFileContent(toOR+1:end)];
        else
            epsFileContent = [epsFileContent(1:fromOR-1) orientStr epsFileContent(toOR+1:fromBB-1) addBBContent epsFileContent(toBB+1:end)];
        end
    else
        epsFileContent = [epsFileContent(1:fromBB-1) addBBContent  epsFileContent(toBB+1:end)];
    end
else
    if changeOrientation    % change content only if orientation is to be changed
        epsFileContent = [epsFileContent(1:fromOR-1) orientStr epsFileContent(toOR+1:end)];
    end
end
%--------------------------------------------------------------------

%--------------------------------------------------------------------
function NL = getnl
% Returns new-line string as found from first occurance from epsFileContent
global epsFileContent

NL = '\r\n';        % default (for Windows systems)
ii = 1;
len = length(epsFileContent);
while ~(epsFileContent(ii)==sprintf('\n') | epsFileContent(ii)==sprintf('\r') | ii<len)
    ii = ii + 1;
end
if epsFileContent(ii)==sprintf('\n')
    NL = '\n';          % unix
elseif epsFileContent(ii)==sprintf('\r')
    NL = '\r';          % macos
    if epsFileContent(ii+1)==sprintf('\n')
        NL = [NL '\n']; % windows
    end
end
NL = sprintf(NL);
%--------------------------------------------------------------------


%--------------------------------------------------------------------
function outstr = strim(str)
% Removes leading and trailing spaces (spaces, tabs, endlines,...)
% from the str string.
if isnumeric(str);
    outstr = str;
    return
end
ind = find( ~isspace(str) );        % indices of the non-space characters in the str    
if isempty(ind)
    outstr = [];        
else
    outstr = str( ind(1):ind(end) );
end
%--------------------------------------------------------------------