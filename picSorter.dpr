program picSorter;
{$SCOPEDENUMS ON}
{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.IOUtils, System.Classes,
  FunctionsCommandLine in '..\SharedCode\FunctionsCommandLine.pas';

type

  TFolderFormat = (YYYYMM=1, YYYYMMDD=2);
  TRenameFormat = (None, ISODateTimeAndMakeModel, ISODateTime);
  TDupCheck = (None, dupFilename, dupEXIF);

  TSorterOptions = record
    Source : string;
    Destination: string;
    DryRun: boolean;
    NoLog : boolean;
    FolderFormat : TFolderFormat;
    Recurse: boolean;
    Rename: TRenameFormat;
    DupCheck: TDupCheck;
    Overwrite: boolean;
    function isValid : boolean;
  end;

var
  i : integer;
  NeedRead: boolean;
  Options: TSorterOptions;

const
  cDryRun = '-DryRun';
  cNoLog = '-NoLog';
  cOver = '-Overwrite';
  cRecurse = '-Recursive';
  cRename = '-Rename=';
  cFormat = '-Format=';
  cDupCheck = '-DupCheck=';
  cOverwrite = '-Overwrite';

procedure ShowHelp;
var
  L : Integer;
const
  HELP : array[0..19] of string = (
    'PicSorter: copies or moves image files into a folder structure based on date of image with optional renaming & logging' ,
    '',
    'USAGE: ',
    'picsorter <source-folder> <dest-base-folder> {/DryRun | /NoLog | /Overwrite | /Recursive | /Rename{number} | /DupCheck }',
    '<source-folder> = Location of the image files that need sorting',
    '<dest-base-folder> = Folder where the images will be copied, sub-folders will be created based on /Format flag',
    ' - '+cFormat+'1 = will create folders based on the number:',
    '   1 = YYYY\MM',
    '   2 = YYYY\MM\DD',
    ' - '+cDryRun+' : will not perform the operation & just logs what would occur',
    ' - '+cNoLog+' : outputs activity to console instead of file',
    ' - '+cOverwrite+' : will overwrite files of same name. Otherwise automatically rename',
    ' - '+cRecurse+' : will recurse any sub-folders from the source folder',
    ' - '+cDupCheck+'1 : will check for duplicates based on 1=Filename, or 2=date, time and make/model of camera (Warning Slow)',
    ' - '+cRename+'1 : will rename the target file based on the number following the param',
    '    1 = YYYYMMDD-HHNNSS-Make-Model',
    '    2 = YYYYMMDD-HHNNSS',
    '',
    'Note that Google filenames are YYYY_MMDD_HHNNSSnnnn where nnnn is a 4 digit number of unknown origin',
    'and will be different to filenames of the same images that are downloaded diretly from the camera'
  );
begin
  for L := 0 to High(HELP) do
    WriteLn(HELP[L]);
  NeedRead := false;
end;

procedure SetDefaultOptions;
begin
  Options.DryRun := false;
  Options.NoLog := false;
  Options.FolderFormat := TFolderFormat.YYYYMM;
  Options.Recurse := True;
  Options.Rename := TRenameFormat.None; // i.e don't
  Options.DupCheck := TDupCheck.None;
end;

function ShowOptions: boolean;
var
  S: String;
  SL : TStringList;
const
  optDryRun: array[boolean] of string = ('', 'Dry Run Only');
  optNoLog : array[boolean] of string = ('Log to file', 'Log to console');
  optOverwrite: array[boolean] of string = ('Auto-rename files with the same name', 'Overwrites files');
  optRecurse: array[boolean] of string = ('Source folder only', 'Source folder and sub-folders');
  optRename: array[TRenameFormat] of string = ('No rename', 'Rename to ISO Date/Time and Make/Model', 'Rename to ISO Date/Time');
  optFormat: array[TFolderFormat] of string = ('Folder format = YYYY\MM', 'Folder Format = YYYY\MM\DD');
  optDupCheck: array[TDupCheck] of string = ('No dupe check', 'Don''t copy files with same name', 'Don''t copy files with same EXIF data');

  procedure StrAdd(const St : string);
  begin
    if St <> '' then
      SL.Add(St);
  end;

begin
  SL := TstringList.Create;
  try
    StrAdd('..........................');
    StrAdd('Options:');
    StrAdd('Source = ' + Options.Source);
    StrAdd('Destination = ' + Options.Destination);
    StrAdd(optFormat[options.FolderFormat]);
    StrAdd(optRecurse[options.Recurse]);
    StrAdd(optRename[options.Rename]);
    StrAdd(optDupCheck[options.DupCheck]);
    StrAdd(optOverwrite[options.Overwrite]);
    StrAdd(optDryRun[options.DryRun]);
    StrAdd(optNoLog[options.NoLog]);

    StrAdd('Press any key to continue or `X` to exit');

    for S in Sl do writeLn(S);

    Readln(s);

    result := UpperCase(S) <> 'X';

  finally
    SL.Free;
  end;
end;

procedure main;
var
  i : integer;
  CP : string;
  Opt: string;
  intOpt : integer;
begin
  if GetParamCount < 3 then
  begin
    ShowHelp;
    Exit;
  end;
  Options.Source := GetParamStr(1);
  if Options.Source = '.' then
    Options.Source := TPath.GetDirectoryName(GetParamStr(0));
  Options.Destination := GetParamStr(2);

  if not Options.isValid then
  begin
    ShowHelp;
    Exit;
  end;

  SetDefaultOptions;

  for i := 3 to GetParamCount-1 do // 0 = executable
  begin
    CP := GetParamStr(i);
    if CP = cDryRun then
      Options.DryRun := true;
    if CP = cNoLog then
      Options.NoLog := true;
    if CP = cOver then
      Options.overwrite := TRUE;
    if Copy(CP, 1, Length(cRename)) = cRename then
    begin
      Opt := Copy(CP, Length(cRename) + 1);
      intOpt := StrToIntDef(Opt, Ord(TRenameFormat.None));
      if (IntOpt >= 0) and (intOpt <= Ord(High(TRenameFormat))) then
        Options.Rename := TRenameFormat(intOpt);
    end;

    if Copy(CP, 1, Length(cFormat)) = cFormat then
    begin
      Opt := Copy(CP, Length(cFormat)+1);
      IntOpt := StrToIntDef(Opt, Ord(TFolderFormat.YYYYMM));
      if (IntOpt >= 0) and (IntOpt <= Ord(High(TFolderFormat))) then
        Options.FolderFormat := TFolderFormat(IntOpt);
    end;

    if Copy(CP, 1, Length(cDupCheck)) = cDupCheck then
    begin
      Opt := Copy(CP, Length(cDupCheck)+1);
      IntOpt := StrToIntDef(Opt, Ord(TDupCheck.None));
      if (IntOpt >= 0) and (IntOpt <= Ord(High(TDupCheck))) then
        Options.DupCheck := TDupCheck(IntOpt);
    end;
  end;

  if ShowOptions then
  begin
    WriteLn('.........working');

  end else
    NeedRead := false;
end;

{ TSorterOptions }

function TSorterOptions.isValid: boolean;
begin
  result := DirectoryExists(Source) and (Destination <> '') and (Copy(Destination,1,1) <> '-') and (Copy(Source, 1, 1) <> '-');
end;

begin
  try
    NeedRead := TRUE;
    {$IF defined(DEBUG)}
      for i := 0 to GetParamCount-1 do
        WriteLn(format('%d = %s', [i, GetParamStr(i)]));
    {$ENDIF}

    main;

    if NeedRead then
      ReadLn;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
