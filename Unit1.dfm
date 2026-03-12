object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'HexaGrid '#8211' Visionneuse hexad'#233'cimale minimalistissime'
  ClientHeight = 424
  ClientWidth = 618
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnShow = FormShow
  TextHeight = 15
  object StringGrid1: TStringGrid
    Left = 0
    Top = 0
    Width = 618
    Height = 424
    Align = alClient
    TabOrder = 0
    OnMouseMove = StringGrid1MouseMove
  end
  object OpenDialog1: TOpenDialog
    Left = 384
    Top = 136
  end
end
