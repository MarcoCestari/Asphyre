object MainForm: TMainForm
  Left = 187
  Top = 101
  Caption = 'Image to ASVF example'
  ClientHeight = 285
  ClientWidth = 330
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
  object Label1: TLabel
    Left = 8
    Top = 10
    Width = 68
    Height = 13
    Caption = 'Image to add:'
  end
  object Bevel1: TBevel
    Left = 19
    Top = 36
    Width = 300
    Height = 2
    Shape = bsTopLine
  end
  object Label2: TLabel
    Left = 27
    Top = 48
    Width = 73
    Height = 13
    Caption = 'Texture Width:'
  end
  object Label3: TLabel
    Left = 24
    Top = 72
    Width = 76
    Height = 13
    Caption = 'Texture Height:'
  end
  object Label4: TLabel
    Left = 178
    Top = 72
    Width = 74
    Height = 13
    Caption = 'Pattern Height:'
  end
  object Label5: TLabel
    Left = 181
    Top = 48
    Width = 71
    Height = 13
    Caption = 'Pattern Width:'
  end
  object Bevel2: TBevel
    Left = 19
    Top = 100
    Width = 300
    Height = 2
    Shape = bsTopLine
  end
  object Label6: TLabel
    Left = 21
    Top = 216
    Width = 86
    Height = 13
    Alignment = taRightJustify
    Caption = 'Destination ASVF:'
  end
  object Bevel3: TBevel
    Left = 19
    Top = 244
    Width = 300
    Height = 2
    Shape = bsTopLine
  end
  object Label7: TLabel
    Left = 126
    Top = 128
    Width = 56
    Height = 13
    Caption = 'Mask Color:'
  end
  object Shape1: TShape
    Left = 188
    Top = 124
    Width = 22
    Height = 22
    OnMouseDown = Shape1MouseDown
  end
  object Label8: TLabel
    Left = 121
    Top = 153
    Width = 51
    Height = 13
    Caption = 'Tolerance:'
  end
  object Bevel4: TBevel
    Left = 19
    Top = 176
    Width = 300
    Height = 2
    Shape = bsTopLine
  end
  object Label9: TLabel
    Left = 96
    Top = 187
    Width = 50
    Height = 13
    Alignment = taRightJustify
    Caption = 'ASVF Key:'
  end
  object Edit1: TEdit
    Left = 80
    Top = 8
    Width = 169
    Height = 21
    TabOrder = 0
    Text = '[select image to add]'
  end
  object BitBtn1: TBitBtn
    Left = 254
    Top = 6
    Width = 75
    Height = 25
    Caption = 'Open'
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000120B0000120B00001000000000000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
      55555555FFFFFFFF5555555000000005555555577777777FF555550999999900
      55555575555555775F55509999999901055557F55555557F75F5001111111101
      105577FFFFFFFF7FF75F00000000000011057777777777775F755070FFFFFF0F
      01105777F555557F75F75500FFFFFF0FF0105577F555FF7F57575550FF700008
      8F0055575FF7777555775555000888888F005555777FFFFFFF77555550000000
      0F055555577777777F7F555550FFFFFF0F05555557F5FFF57F7F555550F000FF
      0005555557F777557775555550FFFFFF0555555557F555FF7F55555550FF7000
      05555555575FF777755555555500055555555555557775555555}
    NumGlyphs = 2
    TabOrder = 1
    OnClick = BitBtn1Click
  end
  object Edit2: TEdit
    Left = 106
    Top = 46
    Width = 57
    Height = 21
    TabOrder = 2
    Text = '256'
  end
  object Edit3: TEdit
    Left = 106
    Top = 70
    Width = 57
    Height = 21
    TabOrder = 3
    Text = '256'
  end
  object Edit4: TEdit
    Left = 258
    Top = 46
    Width = 57
    Height = 21
    TabOrder = 4
    Text = '32'
  end
  object Edit5: TEdit
    Left = 258
    Top = 70
    Width = 57
    Height = 21
    TabOrder = 5
    Text = '32'
  end
  object Edit6: TEdit
    Left = 113
    Top = 213
    Width = 121
    Height = 21
    TabOrder = 6
    Text = '[select dest asvf]'
  end
  object BitBtn2: TBitBtn
    Left = 239
    Top = 211
    Width = 75
    Height = 25
    Caption = 'Open'
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000120B0000120B00001000000000000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00550000000005
      555555777777777FF5555500000000805555557777777777FF555550BBBBB008
      05555557F5FFF7777FF55550B000B030805555F7F777F7F777F550000000B033
      005557777777F7F5775550BBBBB00033055557F5FFF777F57F5550B000B08033
      055557F77757F7F57F5550BBBBB08033055557F55557F7F57F5550BBBBB00033
      055557FFFFF777F57F5550000000703305555777777757F57F555550FFF77033
      05555557FFFFF7FF7F55550000000003055555777777777F7F55550777777700
      05555575FF5555777F55555003B3B3B00555555775FF55577FF55555500B3B3B
      005555555775FFFF77F555555570000000555555555777777755}
    NumGlyphs = 2
    TabOrder = 7
    OnClick = BitBtn2Click
  end
  object BitBtn3: TBitBtn
    Left = 125
    Top = 252
    Width = 80
    Height = 25
    Caption = 'Proceed'
    Default = True
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000130B0000130B00001000000000000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF003333330B7FFF
      FFB0333333777F3333773333330B7FFFFFB0333333777F3333773333330B7FFF
      FFB0333333777F3333773333330B7FFFFFB03FFFFF777FFFFF77000000000077
      007077777777777777770FFFFFFFF00077B07F33333337FFFF770FFFFFFFF000
      7BB07F3FF3FFF77FF7770F00F000F00090077F77377737777F770FFFFFFFF039
      99337F3FFFF3F7F777FF0F0000F0F09999937F7777373777777F0FFFFFFFF999
      99997F3FF3FFF77777770F00F000003999337F773777773777F30FFFF0FF0339
      99337F3FF7F3733777F30F08F0F0337999337F7737F73F7777330FFFF0039999
      93337FFFF7737777733300000033333333337777773333333333}
    NumGlyphs = 2
    TabOrder = 8
    OnClick = BitBtn3Click
  end
  object CheckBox1: TCheckBox
    Left = 68
    Top = 104
    Width = 201
    Height = 17
    Caption = 'Make the following color transparent'
    TabOrder = 9
  end
  object Edit7: TEdit
    Left = 178
    Top = 150
    Width = 39
    Height = 21
    TabOrder = 10
    Text = '15'
  end
  object Edit8: TEdit
    Left = 152
    Top = 184
    Width = 91
    Height = 21
    TabOrder = 11
    Text = 'new ASVF key'
  end
  object OpenDialog1: TOpenDialog
    Filter = 
      'All supported formats|*.png; *.tga; *.jpeg; *.jpg; *.bmp|All fil' +
      'es (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 16
    Top = 72
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'asdb'
    Filter = 'ASVF files (*.asvf)|*.asvf|All files (*.*)|*.*'
    Left = 16
    Top = 40
  end
  object ColorDialog1: TColorDialog
    Left = 16
    Top = 104
  end
end
