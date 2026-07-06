unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  TPointArray = array of TPoint;

  TWKTGeometryType = (wktUnknown, wktPoint, wktLineString, wktPolygon);

  TWKTGeometry = record
    GeoType: TWKTGeometryType;
    Points: array of TPointArray;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Image1: TImage;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);



  private
    function ParsePointList(const S: string): TPointArray;
    function ParseWKT(const WKT: string; out Geo: TWKTGeometry; message: string): boolean;
    function DetectWKTType(const S: string): TWKTGeometryType;
    procedure DrawPoints(Points: array of TPointArray; size: integer = 3);
    procedure DrawLine(Points: array of TPointArray);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);

begin
  FormResize(Sender);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Image1.Width := Form1.ClientWidth - 30;
  Image1.Height := Form1.ClientHeight - 80;
  Edit1.Width := Form1.ClientWidth - 200;
  Button1.Left := Form1.ClientWidth - 190;
  Button2.Left := Form1.ClientWidth - 95;
  Edit1Change(Sender);
end;



procedure TForm1.Edit1Change(Sender: TObject);
begin

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
   Image1.picture := nil;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Geometry: TWKTGeometry;
  success: boolean;
  message: string;
  i: integer;

begin
     success :=  ParseWKT(Edit1.Text, Geometry, message);
     if success then
       Edit1.Color:=clWhite
     else
       begin
            if length(message)>0 then
            begin
                 showMessage(message)
            end;
            Edit1.Color:=clRed;
            exit;
       end;
     Randomize();
     Image1.Canvas.Pen.Width := 5;
     Image1.Canvas.Brush.Color := Random($FFFFFF);

     case Geometry.GeoType of
         wktPoint: drawPoints(Geometry.Points);
         wktLineString: drawLine(Geometry.Points);

     else
        begin
             for i:=0 to Length(Geometry.Points)-1 do
                Image1.Canvas.Polygon(Geometry.Points[i]);
        end;
     end;
end;

procedure TForm1.drawLine(Points: array of TPointArray);
var
  i,j: integer;
begin
     for i := 0 to High(Points) do
        begin

                for j := 0 to High(Points[i])-1 do
                 begin
                  Image1.Canvas.Line(pts[j], pts[j+1]);
                 end;
           end;
end;

procedure TForm1.drawPoints(Points: array of TPointArray; size: integer = 3);
var
  Bounds: TRect;
  i, j: integer;
begin
     for i := 0 to Length(Points)-1 do
     begin
         for j := 0 to Length(Points[i])-1 do
         begin
           Bounds := Rect(Points[i][j].X-size, Points[i][j].Y-size, Points[i][j].X+size, Points[i][j].Y+size);
           Image1.Canvas.Ellipse(Bounds);
         end;
     end;
end;

function TForm1.ParsePointList(const S: string): TPointArray;
var
  parts, xy: TStringList;
  i: Integer;
begin
  parts := TStringList.Create;
  xy := TStringList.Create;
  try
    parts.StrictDelimiter := True;
    parts.Delimiter := ',';
    parts.DelimitedText := S;

    SetLength(Result, parts.Count);

    for i := 0 to parts.Count - 1 do
    begin
      xy.StrictDelimiter := True;
      xy.Delimiter := ' ';
      xy.DelimitedText := Trim(parts[i]);

      if xy.Count < 2 then
        raise EArgumentException.Create('Invalid coordinate pair '+parts[i]);

      Result[i].X := StrToInt(xy[0]);
      Result[i].Y := StrToInt(xy[1]);
    end;
  finally
    parts.Free;
    xy.Free;
  end;
end;

function TForm1.ParseWKT(const WKT: string; out Geo: TWKTGeometry; message: string): boolean;
var
  S, inner: string;
  geoType: TWKTGeometryType;
  parts: TStringList;
  i: Integer;
  ring: string;
begin
  try
    Result := False;
    S := Trim(WKT);

    geoType := DetectWKTType(S);
    Geo.GeoType := geoType;

    if geoType = wktUnknown then Exit;

    inner := Trim(Copy(S, Pos('(', S) + 1, Length(S)));
    if inner.EndsWith(')') then
      inner := inner.Substring(0, inner.Length - 1);

    case geoType of

      wktPoint:
        begin
          SetLength(Geo.Points, 1);
          Geo.Points[0] := ParsePointList(inner);
        end;

      wktLineString:
        begin
          SetLength(Geo.Points, 1);
          Geo.Points[0] := ParsePointList(inner);
        end;

      wktPolygon:
        begin

          parts := TStringList.Create;
          try
            parts.StrictDelimiter := True;
            parts.Delimiter := ')';
            parts.DelimitedText := inner;


            for i := parts.Count - 1 downto 0 do
              if Trim(parts[i]) = '' then
                parts.Delete(i);

            SetLength(Geo.Points, parts.Count);

            for i := 0 to parts.Count - 1 do
            begin

              ring := Trim(parts[i]);
              if ring.StartsWith('(') then
                ring := ring.Substring(1);

              Geo.Points[i] := ParsePointList(ring);
            end;
          finally
            parts.Free;
          end;
        end;

    end;

  except
    On E: EArgumentException do
       begin
            message := E.message;
            Result := False
       end;

  end;

  Result := True;
end;

function TForm1.DetectWKTType(const S: string): TWKTGeometryType;
var U: string;
begin
  U := UpperCase(Trim(S));
  if U.StartsWith('POINT') then Exit(wktPoint);
  if U.StartsWith('LINESTRING') then Exit(wktLineString);
  if U.StartsWith('POLYGON') then Exit(wktPolygon);
  Result := wktUnknown;
end;


end.

