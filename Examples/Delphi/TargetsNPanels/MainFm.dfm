object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Targets'#39'n'#39'Panels - Asphyre Sphinx'
  ClientHeight = 278
  ClientWidth = 535
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 256
    Height = 256
    Caption = 'Panel1'
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 270
    Top = 8
    Width = 256
    Height = 256
    Caption = 'Panel2'
    TabOrder = 1
  end
end
