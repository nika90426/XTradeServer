//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

struct WinCell;

#include <XTrade\IUtils.mqh>
#include <Canvas\Canvas.mqh>

class PanelBase;

//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Структура свойств объектов WinCell                               |
//+------------------------------------------------------------------+
struct WinCell
{
   WinCell()
   {
      Transparency = 140;
      TextColor = clrWhite;
      BGColor = clrSteelBlue;
      BGEditColor = clrDimGray;
      Corner=CORNER_LEFT_UPPER;
      Corn = 1;
      H = 22;
   }
   WinCell(PanelBase* panel)
   {
      Transparency = panel.Property.Transparency;
      TextColor = panel.Property.TextColor;
      BGColor = panel.Property.BGColor;
      BGEditColor = panel.Property.BGEditColor;
      Corner = panel.Property.Corner;
      Corn = panel.Property.Corn;
      H = panel.Property.H;
   }
   uint             TextColor;     // цвет текста
   uint             BGColor;       // цвет фона
   uint             BGEditColor;   // цвет фона при редактировании
   ENUM_BASE_CORNER  Corner;        // угол привязки
   int               H;             // высота ячейки
   int               Corn;          // направление смещения (1;-1)
   uchar             Transparency;   
};

class PanelBase 
{
protected:
   bool              on_event;   // флаг обработки событий

   long              Y_hide;          // величина сдвига окна
   long              Y_obj;           // величина сдвига окна
   long              H_obj;           // величина сдвига окна
   void              SetXY(int m_corner);// Метод расчёта координат
   //datetime          RaiseTime; //Timer raise time
   bool              bForceRedraw;
public:
   long              chartID;
   int               subWin;

   int               w_corner;   // угол привязки
   int               w_xdelta;   // вертикальный отступ
   int               w_ydelta;   // горизонтальный отступ
   int               w_xpos;     // координата X точки привязки
   int               w_ypos;     // координата Y точки привязки
   int               w_bsize;    // ширина окна
   int               w_hsize;    // высота окна
   int               w_h_corner; // угол привязки HIDE режима
   WinCell           Property;   // свойства окна

   template<typename T> void EnumArrayStrings(string &arr[], int size)
   {
      ArrayResize(arr, size);
      for(int i=0; i < size; i++)
         arr[i] = EnumToString((T)i);
   }
   
   template<typename T> T EnumValueFromString(string &arr[], string value, T def)
   {
      for(int i=0; i < ArraySize(arr); i++)
      {
         if (StringCompare(arr[i], value) ==0)
            return (T)i;
      }
      return (T)def;
   }

   PanelBase(long ChartId, int sWin ) 
   {
      chartID = ChartId;
      subWin = sWin;
      on_event = false;
    }
   
   virtual void ~PanelBase() 
   {
   }
   
   virtual void              Draw() = 0;


   virtual void              SetWin(int m_xdelta,
                             int m_ydelta,
                             int m_bsize,
                             int m_corner);
   
   datetime RefreshTFNow;
   virtual bool AllowRedrawByEvenMinutesTimer(string Sym, ENUM_TIMEFRAMES tf)
   {
      datetime currentBar = iTime(Sym, tf, 0);
      if (RefreshTFNow == currentBar)
          return false;
      RefreshTFNow = currentBar;
      return true;
   }
   
   virtual void SetForceRedraw()
   {
       bForceRedraw = true;
   }

};


//+------------------------------------------------------------------+
void PanelBase::SetXY(int m_corner)
{
   if((ENUM_BASE_CORNER)m_corner==CORNER_LEFT_UPPER)
     {
      w_xpos=w_xdelta;
      w_ypos=w_ydelta;
      Property.Corn=1;
     }
   else
   if((ENUM_BASE_CORNER)m_corner==CORNER_RIGHT_UPPER)
     {
      w_xpos=w_xdelta+w_bsize;
      w_ypos=w_ydelta;
      Property.Corn=-1;
     }
   else
   if((ENUM_BASE_CORNER)m_corner==CORNER_LEFT_LOWER)
     {
      w_xpos=w_xdelta;
      w_ypos=w_ydelta+w_hsize+Property.H;
      Property.Corn=1;
     }
   else
   if((ENUM_BASE_CORNER)m_corner==CORNER_RIGHT_LOWER)
     {
      w_xpos=w_xdelta+w_bsize;
      w_ypos=w_ydelta+w_hsize+Property.H;
      Property.Corn=-1;
     }
   else
     {
      Print("Error setting the anchor corner = ",m_corner);
      w_corner=CORNER_LEFT_UPPER;
      w_xpos=0;
      w_ypos=0;
      Property.Corn=1;
     }
//---
   if((ENUM_BASE_CORNER)w_corner==CORNER_LEFT_UPPER) w_h_corner=CORNER_LEFT_LOWER;
   if((ENUM_BASE_CORNER)w_corner==CORNER_LEFT_LOWER) w_h_corner=CORNER_LEFT_LOWER;
   if((ENUM_BASE_CORNER)w_corner==CORNER_RIGHT_UPPER) w_h_corner=CORNER_RIGHT_LOWER;
   if((ENUM_BASE_CORNER)w_corner==CORNER_RIGHT_LOWER) w_h_corner=CORNER_RIGHT_LOWER;
//---
}

//+------------------------------------------------------------------+
void PanelBase::SetWin(int m_xdelta,
                  int m_ydelta,
                  int m_bsize,
                  int m_corner)
{
//---
   if((ENUM_BASE_CORNER)m_corner==CORNER_LEFT_UPPER) w_corner=m_corner;
   else
      if((ENUM_BASE_CORNER)m_corner==CORNER_RIGHT_UPPER) w_corner=m_corner;
   else
      if((ENUM_BASE_CORNER)m_corner==CORNER_LEFT_LOWER) w_corner=CORNER_LEFT_UPPER;
   else
      if((ENUM_BASE_CORNER)m_corner==CORNER_RIGHT_LOWER) w_corner=CORNER_RIGHT_UPPER;
   else
     {
      Print("Error setting the anchor corner = ",m_corner);
      w_corner=CORNER_LEFT_UPPER;
     }
   if(m_xdelta>=0)w_xdelta=m_xdelta;
   else
     {
      Print("The offset error X = ",m_xdelta);
      w_xdelta=0;
     }
   if(m_ydelta>=0)w_ydelta=m_ydelta;
   else
     {
      Print("The offset error Y = ",m_ydelta);
      w_ydelta=0;
     }
   if(m_bsize>0)
     w_bsize=m_bsize;
   
   Property.Corner=(ENUM_BASE_CORNER)w_corner;
   SetXY(w_corner);
}

