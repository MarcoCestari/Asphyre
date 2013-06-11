object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Asphyre Sphinx: NetCom example'
  ClientHeight = 280
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object IncomingGroupBox: TGroupBox
    Left = 8
    Top = 8
    Width = 412
    Height = 137
    Caption = ' Incoming Messages '
    TabOrder = 0
    object IncomingMemo: TMemo
      Left = 6
      Top = 18
      Width = 400
      Height = 112
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
  object SendGroupBox: TGroupBox
    Left = 8
    Top = 151
    Width = 412
    Height = 96
    Caption = ' Send Message '
    TabOrder = 1
    object DestHostLabel: TLabel
      Left = 86
      Top = 19
      Width = 83
      Height = 13
      Alignment = taRightJustify
      Caption = 'Destination Host:'
    end
    object DestPortLabel: TLabel
      Left = 88
      Top = 43
      Width = 81
      Height = 13
      Alignment = taRightJustify
      Caption = 'Destination Port:'
    end
    object MessageLabel: TLabel
      Left = 11
      Top = 70
      Width = 46
      Height = 13
      Alignment = taRightJustify
      Caption = 'Message:'
    end
    object DestHostEdit: TEdit
      Left = 175
      Top = 16
      Width = 150
      Height = 21
      TabOrder = 0
      Text = '127.0.0.1'
    end
    object DestPortEdit: TEdit
      Left = 175
      Top = 40
      Width = 150
      Height = 21
      TabOrder = 1
      Text = '7500'
    end
    object TextEdit: TEdit
      Left = 63
      Top = 67
      Width = 272
      Height = 21
      TabOrder = 2
      Text = 'Hello world there!'
    end
    object SendButton: TButton
      Left = 341
      Top = 65
      Width = 60
      Height = 25
      Caption = 'Send'
      TabOrder = 3
      OnClick = SendButtonClick
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 261
    Width = 430
    Height = 19
    Panels = <
      item
        Text = 'Local IP: Unknown'
        Width = 150
      end
      item
        Text = 'Local Port: Unknown'
        Width = 150
      end>
  end
  object SysTimer: TTimer
    Interval = 100
    OnTimer = SysTimerTimer
    Left = 368
    Top = 168
  end
end
