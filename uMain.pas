unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, IniPropStorage, EditBtn, StdCtrls, Windows, ShellApi, Process;

type

  { TfMain }

  TfMain = class(TForm)
    deAppsFolder: TDirectoryEdit;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    lvApps: TListView;
    pcMain: TPageControl;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvAppsDblClick(Sender: TObject);
    procedure pcMainChange(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fMain: TfMain;

implementation

{$R *.lfm}

{ TfMain }

// Recursive procedure to build a list of files
procedure FindFiles(FilesList: TStringList; StartDir, FileMask: string);
var
  SR: SysUtils.TSearchRec;
  DirList: TStringList;
  IsFound: boolean;
  i: integer;
  LargeIco, SmallIco: Windows.hIcon;
  myIcon: TIcon;
begin
  if StartDir[Length(StartDir)] <> '\' then
    StartDir := StartDir + '\';

  { Build a list of the files in directory StartDir
     (not the directories!)                         }

  IsFound := FindFirst(StartDir + FileMask, faAnyFile - faDirectory, SR) = 0;
  while IsFound do
  try
    //FilesList.Add(StartDir + SR.Name);
    with fMain.lvApps.Items.Add do
    begin
      Application.ProcessMessages;
      Caption := ChangeFileExt(SR.Name, '');
      SubItems.Add(StartDir + SR.Name);
      if ShellApi.ExtractIconEx(PChar(StartDir + SR.Name), 0, LargeIco,
        SmallIco, 1) > Null then
      begin
        myIcon := TIcon.Create;
        try
          myIcon.Transparent := True;
          myIcon.Masked := True;
          myIcon.Handle := LargeIco;
          fMain.ImageList1.AddIcon(myIcon);
          {lvApps.}ImageIndex := fMain.ImageList1.Count - 1;
          //{lvApps.}Enabled:= True;
          //{lvApps.}OnClick:= @tbToolsClick;
        finally
          myIcon.Free;
        end;
      end
      else
      begin
        {lvApps.}ImageIndex := 0;
        //{lvApps.}Enabled:= False;
      end;
    end;
    IsFound := FindNext(SR) = 0;
  except

  end;
  SysUtils.FindClose(SR);

  // Build a list of subdirectories
  DirList := TStringList.Create;
  IsFound := FindFirst(StartDir + '*.*', faAnyFile, SR) = 0;
  while IsFound do
  begin
    if ((SR.Attr and faDirectory) <> 0) and (SR.Name[1] <> '.') then
      DirList.Add(StartDir + SR.Name);
    IsFound := FindNext(SR) = 0;
  end;
  SysUtils.FindClose(SR);

  // Scan the list of subdirectories
  for i := 0 to DirList.Count - 1 do
    FindFiles(FilesList, DirList[i], FileMask);

  DirList.Free;
end;

procedure TfMain.FormActivate(Sender: TObject);
begin
  pcMainChange(Sender);
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  pcMainChange(Sender);
end;

procedure TfMain.lvAppsDblClick(Sender: TObject);
var
  AProcess: Process.TProcess;
begin
  if lvApps.ItemIndex < 0 then
    Exit;

  if not FileExists(lvApps.Selected.SubItems[0]) then
    Exit;

  {If cbxAppLaunch.Checked Then
    If MessageDlg('Launch '+ TToolButton(Sender).Caption+ '?', mtConfirmation, [mbYes, mbNo], 0)= mrNo Then
      Exit;

  If cbxAppAdmin.Checked Then
     Begin
       RunAsAdmin(fMain.Handle, TToolButton(Sender).Hint, '');
       Exit;
     End;}

  AProcess := TProcess.Create(nil);
  AProcess.Executable := lvApps.Selected.SubItems[0];
  {If cbxAppWait.Checked Then
    AProcess.Options := AProcess.Options + [poWaitOnExit];}
  AProcess.Execute;
  AProcess.Free;
end;

procedure TfMain.pcMainChange(Sender: TObject);
var
  FilesList: TStringList;
begin
  if not DirectoryExists(deAppsFolder.Directory) then
    deAppsFolder.Directory := ExcludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

  if pcMain.TabIndex = 0 then
  begin
    ImageList1.Clear;
    lvApps.Clear;
    FilesList := TStringList.Create;
    try
      FindFiles(FilesList, deAppsFolder.Directory, '*.exe');
    finally
      FilesList.Free;
    end;
  end;
end;

end.
