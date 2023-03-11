object Form3: TForm3
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Crofoname'
  ClientHeight = 376
  ClientWidth = 249
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 16
    Top = 156
    Width = 39
    Height = 13
    Caption = 'Patern :'
  end
  object Edit_Patern: TEdit
    Left = 64
    Top = 152
    Width = 145
    Height = 21
    TabOrder = 0
    Text = 'Edit_Patern'
    OnExit = Edit_PaternExit
  end
  object btt_cancel: TButton
    Left = 16
    Top = 344
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = btt_cancelClick
  end
  object btt_ok: TButton
    Left = 160
    Top = 344
    Width = 75
    Height = 25
    Caption = 'Rename'
    TabOrder = 2
    OnClick = btt_okClick
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 0
    Width = 233
    Height = 145
    Caption = 'Wizard'
    TabOrder = 3
    object Label1: TLabel
      Left = 8
      Top = 28
      Width = 49
      Height = 13
      Caption = 'Filename :'
    end
    object Label3: TLabel
      Left = 104
      Top = 64
      Width = 19
      Height = 13
      Caption = '( ? )'
    end
    object Label4: TLabel
      Left = 104
      Top = 88
      Width = 19
      Height = 13
      Caption = '(%)'
    end
    object Label5: TLabel
      Left = 104
      Top = 112
      Width = 20
      Height = 13
      Caption = '( * )'
    end
    object Edit_Filename: TEdit
      Left = 64
      Top = 24
      Width = 145
      Height = 21
      TabOrder = 0
    end
    object chk_Date: TCheckBox
      Left = 16
      Top = 64
      Width = 81
      Height = 17
      Caption = 'Date'
      TabOrder = 1
      OnClick = chk_DateClick
    end
    object chk_Time: TCheckBox
      Left = 16
      Top = 88
      Width = 81
      Height = 17
      Caption = 'Time'
      TabOrder = 2
      OnClick = chk_TimeClick
    end
    object chk_numerical: TCheckBox
      Left = 16
      Top = 112
      Width = 81
      Height = 17
      Caption = 'Numerical'
      Checked = True
      State = cbChecked
      TabOrder = 3
      OnClick = chk_numericalClick
    end
    object Btt_genpatern: TButton
      Left = 136
      Top = 56
      Width = 73
      Height = 81
      Caption = 'Generate patern'
      TabOrder = 4
      WordWrap = True
      OnClick = Btt_genpaternClick
    end
  end
  object ProgressBar1: TProgressBar
    Left = 8
    Top = 184
    Width = 233
    Height = 17
    TabOrder = 4
  end
  object chk_prev: TCheckBox
    Left = 16
    Top = 212
    Width = 217
    Height = 17
    Caption = 'Preview Filename :'
    Checked = True
    State = cbChecked
    TabOrder = 5
    OnClick = chk_prevClick
  end
  object ListView_prev: TListView
    Left = 16
    Top = 240
    Width = 217
    Height = 94
    Columns = <>
    TabOrder = 6
    ViewStyle = vsSmallIcon
  end
end
