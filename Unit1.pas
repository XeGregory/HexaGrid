unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids;

type
  TForm1 = class(TForm)
    StringGrid1: TStringGrid;
    OpenDialog1: TOpenDialog;
    procedure FormShow(Sender: TObject);
    procedure StringGrid1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

  private
    { Déclarations privées }
    FLastHintCol, FLastHintRow: Integer;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ -------------------------------------------------------------
  AutoSizeStringGridColumns
  Ajuste automatiquement la largeur de chaque colonne du TStringGrid
  en fonction du texte le plus large qu'elle contient, plus une marge.

  Paramètres :
  Grid   : le StringGrid à ajuster
  Margin : marge (en pixels) à ajouter des deux côtés du texte
  -------------------------------------------------------------- }
procedure AutoSizeStringGridColumns(Grid: TStringGrid; Margin: Integer = 8);
var
  C, R: Integer;
  MaxW, W: Integer;
begin
  // On s'assure que le Canvas utilise la même police que la grille
  Grid.Canvas.Font := Grid.Font;

  for C := 0 to Grid.ColCount - 1 do
  begin
    MaxW := 0;
    // Pour chaque ligne, calculer la largeur du texte de la cellule [c,r]
    for R := 0 to Grid.RowCount - 1 do
    begin
      W := Grid.Canvas.TextWidth(Grid.Cells[C, R]);
      if W > MaxW then
        MaxW := W; // On garde la largeur maximale
    end;
    // On fixe la largeur de la colonne : largeur max + marge des deux côtés
    Grid.ColWidths[C] := MaxW + Margin * 2;
  end;
end;

{ -------------------------------------------------------------
  LoadFileHexToGrid
  Charge le contenu d'un fichier binaire dans le TStringGrid,
  affichage en hexadécimal et ASCII.

  Paramètres :
  FileName     : chemin complet du fichier à lire
  Grid         : TStringGrid dans lequel afficher les données
  BytesPerLine : nombre d'octets par ligne (par défaut 16)
  -------------------------------------------------------------- }
procedure LoadFileHexToGrid(const FileName: string; Grid: TStringGrid; BytesPerLine: Integer = 16);
var
  Fs: TFileStream;
  Buffer: TBytes;
  RowCount, FullLines, LastLineBytes: Integer;
  R, C, readCnt: Integer;
  AsciiLine: string;
begin
  // Ouvre le fichier en mode lecture, sans permettre l'écriture concurrente
  Fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    // Calcul du nombre de lignes complètes et des octets restants
    FullLines := Fs.Size div BytesPerLine;
    LastLineBytes := Fs.Size mod BytesPerLine;
    // +1 pour la ligne de titre, +1 si reste d'octets
    RowCount := FullLines + Ord(LastLineBytes > 0) + 1;

    Grid.BeginUpdate; // Bloque le rafraîchissement visuel pour optimiser
    try
      // Configuration de la grille : colonnes (octets + offset + ASCII) et lignes
      Grid.ColCount := BytesPerLine + 2;
      Grid.RowCount := RowCount;
      Grid.FixedRows := 1; // Une ligne figée pour les en-têtes
      Grid.Options := Grid.Options + [goFixedVertLine, goFixedHorzLine];

      // En-têtes de colonnes
      Grid.Cells[0, 0] := 'Offset';
      for C := 1 to BytesPerLine do
        Grid.Cells[C, 0] := IntToHex(C - 1, 2);
      Grid.Cells[BytesPerLine + 1, 0] := 'ASCII';

      SetLength(Buffer, BytesPerLine);

      // Lecture ligne par ligne
      for R := 0 to RowCount - 2 do
      begin
        Fs.Position := R * BytesPerLine;
        readCnt := Fs.Read(Buffer[0], BytesPerLine);

        // Affiche l’offset en hexadécimal sur 8 caractères
        Grid.Cells[0, R + 1] := '$' + IntToHex(R * BytesPerLine, 8);

        // Pour chaque octet lu, affiche son hexadécimal ou laisse vide sinon
        for C := 0 to BytesPerLine - 1 do
          if C < readCnt then
            Grid.Cells[C + 1, R + 1] := IntToHex(Buffer[C], 2)
          else
            Grid.Cells[C + 1, R + 1] := '';

        // Construction de la chaîne de caractères ASCII
        AsciiLine := '';
        for C := 0 to readCnt - 1 do
          if Buffer[C] in [32 .. 126] then
            AsciiLine := AsciiLine + Chr(Buffer[C])
          else
            AsciiLine := AsciiLine + '.';
        Grid.Cells[BytesPerLine + 1, R + 1] := AsciiLine;
      end;
    finally
      Grid.EndUpdate; // Débloque le rafraîchissement visuel
    end;

    // Ajuste automatiquement la largeur des colonnes
    AutoSizeStringGridColumns(Grid, 6);
  finally
    Fs.Free; // Libère la ressource du fichier
  end;
end;

{ -------------------------------------------------------------
  FormShow
  Lors de l'affichage du formulaire, ouvre un dialogue pour
  sélectionner un fichier, puis charge son contenu en hex.
  -------------------------------------------------------------- }
procedure TForm1.FormShow(Sender: TObject);
begin
  StringGrid1.Font.Name := 'Consolas';
  // On active le hint et on initialise les coords « dernière cellule »
  StringGrid1.ShowHint := True;
  FLastHintCol := -1;
  FLastHintRow := -1;

  // Affiche le hex-dump
  if OpenDialog1.Execute then
    LoadFileHexToGrid(OpenDialog1.FileName, StringGrid1, 16);
end;

procedure TForm1.StringGrid1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
  hexText: string;
  value: Integer;
  asciiChar: Char;
begin
  StringGrid1.MouseToCell(X, Y, ACol, ARow);

  // On ne refait pas le hint si on reste dans la même cellule
  if (ACol = FLastHintCol) and (ARow = FLastHintRow) then
    Exit;
  FLastHintCol := ACol;
  FLastHintRow := ARow;

  // On ne s’intéresse qu’aux colonnes hex (1..BytesPerLine) et aux lignes de données (>0)
  if (ARow > 0) and (ACol > 0) and (ACol <= 16) then
  begin
    hexText := StringGrid1.Cells[ACol, ARow];
    // conversion sûre en décimal
    if TryStrToInt('$' + hexText, value) then
    begin
      if value in [32 .. 126] then
        asciiChar := Chr(value)
      else
        asciiChar := '.';
      StringGrid1.Hint := Format('Décimal: %d   ASCII: %s', [value, asciiChar]);
    end
    else
      StringGrid1.Hint := '';
  end
  else
    StringGrid1.Hint := '';
end;

end.
