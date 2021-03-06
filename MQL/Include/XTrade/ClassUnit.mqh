//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

//--- Объявление констант
#define  MAX_WIN     50    // код кнопки
#define  MIN_WIN     48    // код кнопки
#define  CLOSE_WIN   208   // код кнопки
#define  PAGE_UP     112   // код кнопки
#define  PAGE_DOWN   113   // код кнопки
#define  TIME_SLEEP  50    // "тормоз" на реакцию события
#define  DEF_Z_ORDER 1000

#include <XTrade\IUtils.mqh>
#include <XTrade\PanelBase.mqh>
#include <Canvas\Canvas.mqh>

//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Базовый класс ЯЧЕЙКА  CCell                                      |
//+------------------------------------------------------------------+
class CCell
  {
private:
protected:
   bool              on_event;      // флаг обработки событий
   ENUM_OBJECT       type;          // тип ячейки
   PanelBase*        parent;
public:
   WinCell           Property;      // свойства ячейки
   string            name;          // имя ячейки

   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CCell(PanelBase* panel);
   virtual void              ~CCell()
   {
      Delete();
   }
   virtual     // Метод: нарисовать объект
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   virtual void Delete()
   {
      ObjectDelete(parent.chartID, name);
   }

  };
//+------------------------------------------------------------------+
//| Конструктор класса CCell                                         |
//+------------------------------------------------------------------+
void CCell::CCell(PanelBase* panel)
  :Property(panel)
{
   parent = panel;
   on_event=false;   // запрещаем обработку событий
}
//+------------------------------------------------------------------+
//| Метод Draw класса CCell                                          |
//+------------------------------------------------------------------+
void CCell::Draw(string m_name,
                 int m_xdelta,
                 int m_ydelta,
                 int m_bsize)
  {
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CCell                |
//+------------------------------------------------------------------+
void CCell::OnEvent(const int id,
                    const long &lparam,
                    const double &dparam,
                    const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      //--- нажатие кнопки
      if((ENUM_CHART_EVENT)id==CHARTEVENT_OBJECT_CLICK && StringFind(sparam,".Button",0)>0)
        {
         if(ObjectGetInteger(0,sparam,OBJPROP_STATE)==1)
           {
            //--- если кнопка залипла
            Sleep(TIME_SLEEP);
            ObjectSetInteger(parent.chartID,sparam,OBJPROP_STATE,0);
            ChartRedraw(parent.chartID);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс ЯЧЕЙКА:  CCellText                                         |
//+------------------------------------------------------------------+
class CCellText:public CCell
{
protected:
   CCanvas c;
   string m_text;
public:
   // Конструктор класса
   void              CCellText(PanelBase* p);
   void SetText(string newText)
   {
      m_text = newText;
   }
   
   virtual void Delete()
   {
      c.Destroy();
      ObjectDelete(parent.chartID, name);
   }

   virtual     // Метод: нарисовать объект
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize);
};
//+------------------------------------------------------------------+
//| Конструктор класса CCellText                                     |
//+------------------------------------------------------------------+
void CCellText::CCellText(PanelBase* p)
  :CCell(p)
{
   type=OBJ_EDIT;
   on_event=false;   // запрещаем обработку событий
}
//+------------------------------------------------------------------+
//| Метод Draw класса CCellText                                      |
//+------------------------------------------------------------------+
void CCellText::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize)
  {
//--- создаём объект с модифицированным именем
   name=m_name+".Text";
   if (Property.Transparency < 255)
   {
      if (ObjectFind(parent.chartID, name) == -1)
      {
         c.Destroy();
         if(!c.CreateBitmapLabel(parent.chartID, parent.subWin, name, m_xdelta,m_ydelta,m_bsize,Property.H,COLOR_FORMAT_ARGB_NORMALIZE))
         {
            Utils.Debug(StringFormat("Error creating canvas %s : error=%d ", name, GetLastError()));
            return;
         }
      } else {
         ObjectSetInteger(parent.chartID,name,OBJPROP_XDISTANCE,m_xdelta);
         ObjectSetInteger(parent.chartID,name,OBJPROP_YDISTANCE,m_ydelta);
      }
      ObjectSetInteger(parent.chartID,name,OBJPROP_ZORDER,DEF_Z_ORDER);      

      c.Erase();
      c.FontSet("Arial", -10*10);
      c.TextOut(0, 0, m_text, Property.TextColor);
      c.TransparentLevelSet(Property.Transparency);
      c.Update();
   } else {
   
         if (ObjectFind(parent.chartID, name) == -1)
      
         if(ObjectCreate(parent.chartID,name, type, parent.subWin,0,0,0,0) == false)
            Utils.Debug(StringFormat("Function %s error %d", __FUNCTION__,GetLastError()));
      //--- инициализируем свойства объекта
         ObjectSetInteger(parent.chartID,name,OBJPROP_ZORDER,DEF_Z_ORDER);
         ObjectSetInteger(parent.chartID,name,OBJPROP_COLOR,Property.TextColor);
         ObjectSetInteger(parent.chartID,name,OBJPROP_BGCOLOR,Property.BGColor);
         ObjectSetInteger(parent.chartID,name,OBJPROP_READONLY,true);
         ObjectSetInteger(parent.chartID,name,OBJPROP_CORNER,Property.Corner);
         ObjectSetInteger(parent.chartID,name,OBJPROP_XDISTANCE,m_xdelta);
         ObjectSetInteger(parent.chartID,name,OBJPROP_YDISTANCE,m_ydelta);
         ObjectSetInteger(parent.chartID,name,OBJPROP_XSIZE,m_bsize);
         ObjectSetInteger(parent.chartID,name,OBJPROP_YSIZE,Property.H);
         ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Arial");
         ObjectSetString(parent.chartID,name,OBJPROP_TEXT,m_text);
         ObjectSetString(parent.chartID,name,OBJPROP_TOOLTIP,m_text);
         ObjectSetInteger(parent.chartID,name,OBJPROP_ZORDER,1000);
         
         ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,10);
         ObjectSetInteger(parent.chartID,name,OBJPROP_SELECTABLE,0);
   }
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс ЯЧЕЙКА:  CCellEdit                                         |
//+------------------------------------------------------------------+
class CCellEdit:public CCell
  {
   string m_text;
public:
   // Конструктор класса
   void              CCellEdit(PanelBase* p);
   virtual     // Метод: нарисовать объект
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize, bool m_read);
   string GetText()
   {
      return ObjectGetString(parent.chartID,name,OBJPROP_TEXT);
   }

   void SetText(string newText)
   {
      m_text = newText;
   }
      
  };
//+------------------------------------------------------------------+
//| Конструктор класса CCellEdit                                     |
//+------------------------------------------------------------------+
void CCellEdit::CCellEdit(PanelBase* p)
  :CCell(p)
{
   type = OBJ_EDIT;
   on_event = false;   // запрещаем обработку событий
}
//+------------------------------------------------------------------+
//| Метод Draw класса CCellEdit                                      |
//+------------------------------------------------------------------+
void CCellEdit::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     bool m_read)
{
//--- создаём объект с модифицированным именем
   name=m_name+".Edit";
   if (ObjectFind(parent.chartID, name) == -1)
   if(ObjectCreate(parent.chartID, name, type, parent.subWin,0,0,0,0)==false)
      Utils.Debug(StringFormat("Function %s error %d",__FUNCTION__,GetLastError()));
   //--- инициализируем свойства объекта
   ObjectSetInteger(parent.chartID,name,OBJPROP_ZORDER,DEF_Z_ORDER);
   ObjectSetInteger(parent.chartID,name,OBJPROP_COLOR,Property.TextColor);
   ObjectSetInteger(parent.chartID,name,OBJPROP_BGCOLOR,Property.BGEditColor);
   ObjectSetInteger(parent.chartID,name,OBJPROP_READONLY,m_read);
   ObjectSetInteger(parent.chartID,name,OBJPROP_CORNER,Property.Corner);
   ObjectSetInteger(parent.chartID,name,OBJPROP_XDISTANCE,m_xdelta);
   ObjectSetInteger(parent.chartID,name,OBJPROP_YDISTANCE,m_ydelta);
   ObjectSetInteger(parent.chartID,name,OBJPROP_XSIZE,m_bsize);
   ObjectSetInteger(parent.chartID,name,OBJPROP_YSIZE,Property.H);
   ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Arial");
   ObjectSetString(parent.chartID,name,OBJPROP_TEXT,m_text);
   ObjectSetString(parent.chartID,name,OBJPROP_TOOLTIP,m_text);
   ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(parent.chartID,name,OBJPROP_SELECTABLE,0);
   //---
   on_event=true;   // разрешаем обработку событий
}
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс ЯЧЕЙКА:  CCellButton                                       |
//+------------------------------------------------------------------+
class CCellButton:public CCell
  {
public:
   // Конструктор класса
   void              CCellButton(PanelBase* p);
   virtual     // Метод: нарисовать объект
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          string m_button);
  };
//+------------------------------------------------------------------+
//| Конструктор класса CCellButton                                   |
//+------------------------------------------------------------------+
void CCellButton::CCellButton(PanelBase* p)
:CCell(p)
{
   type=OBJ_BUTTON;
   on_event=false;   // запрещаем обработку событий
}
//+------------------------------------------------------------------+
//| Метод Draw класса CCellButton                                    |
//+------------------------------------------------------------------+
void CCellButton::Draw(string m_name,
                       int m_xdelta,
                       int m_ydelta,
                       int m_bsize,
                       string m_button)
  {
//--- создаём объект с модифицированным именем
   name=m_name+".Button";
   if (ObjectFind(parent.chartID, name) == -1)
      if(ObjectCreate(parent.chartID,name,type,parent.subWin,0,0,0,0)==false)
          Utils.Debug(StringFormat("Function %s error %d",__FUNCTION__,GetLastError()));
//--- инициализируем свойства объекта
   ObjectSetInteger(parent.chartID,name,OBJPROP_ZORDER,DEF_Z_ORDER);
   ObjectSetInteger(parent.chartID,name,OBJPROP_COLOR,Property.TextColor);
   ObjectSetInteger(parent.chartID,name,OBJPROP_BGCOLOR,Property.BGColor);
   ObjectSetInteger(parent.chartID,name,OBJPROP_CORNER,Property.Corner);
   ObjectSetInteger(parent.chartID,name,OBJPROP_XDISTANCE,m_xdelta);
   ObjectSetInteger(parent.chartID,name,OBJPROP_YDISTANCE,m_ydelta);
   ObjectSetInteger(parent.chartID,name,OBJPROP_XSIZE,m_bsize);
   ObjectSetInteger(parent.chartID,name,OBJPROP_YSIZE,Property.H);
   ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Arial");
   ObjectSetString(parent.chartID,name,OBJPROP_TEXT,m_button);
   ObjectSetString(parent.chartID,name,OBJPROP_TOOLTIP,m_button);
   ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(parent.chartID,name,OBJPROP_SELECTABLE,0);
//---
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс ЯЧЕЙКА:  CCellButtonType                                   |
//+------------------------------------------------------------------+
class CCellButtonType:public CCell
  {
public:
   // Конструктор класса
   void              CCellButtonType(PanelBase* p);
   virtual     // Метод: нарисовать объект
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_type);
   virtual void Delete()
   {
      ObjectDelete(parent.chartID, name);
   }
  };
//+------------------------------------------------------------------+
//| Конструктор класса CCellButtonType                               |
//+------------------------------------------------------------------+
void CCellButtonType::CCellButtonType(PanelBase* p)
 :CCell(p)
  {
   type=OBJ_BUTTON;
   on_event=false;   // запрещаем обработку событий
  }
//+------------------------------------------------------------------+
//| Метод Draw класса CCellButtonType                                |
//+------------------------------------------------------------------+
void CCellButtonType::Draw(string m_name,
                           int m_xdelta,
                           int m_ydelta,
                           int m_type)
  {
//--- создаём объект с модифицированным именем
   if(m_type<=0) m_type=0;
   name=m_name+".Button"+(string)m_type;
   if (ObjectFind(parent.chartID, name) == -1)
      if(ObjectCreate(0,name,type,parent.subWin,0,0,0,0)==false)
         Utils.Debug(StringFormat("Function %s error %d",__FUNCTION__,GetLastError()));

//--- инициализируем свойства объекта
   ObjectSetInteger(parent.chartID,name,OBJPROP_ZORDER,DEF_Z_ORDER);
   ObjectSetInteger(parent.chartID,name,OBJPROP_COLOR,Property.TextColor);
   ObjectSetInteger(parent.chartID,name,OBJPROP_BGCOLOR,Property.BGColor);
   ObjectSetInteger(parent.chartID,name,OBJPROP_CORNER,Property.Corner);
   ObjectSetInteger(parent.chartID,name,OBJPROP_XDISTANCE,m_xdelta);
   ObjectSetInteger(parent.chartID,name,OBJPROP_YDISTANCE,m_ydelta);
   ObjectSetInteger(parent.chartID,name,OBJPROP_XSIZE,Property.H);
   ObjectSetInteger(parent.chartID,name,OBJPROP_YSIZE,Property.H);
   ObjectSetInteger(parent.chartID,name,OBJPROP_SELECTABLE,0);
   if(m_type==0) // Кнопка Hide
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,CharToString(MIN_WIN));
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Webdings");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,12);
     }
   if(m_type==1) // Кнопка Close
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,CharToString(CLOSE_WIN));
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Wingdings 2");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,8);
     }
   if(m_type==2) // Кнопка Return
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,CharToString(MAX_WIN));
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Webdings");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,12);
     }
   if(m_type==3) // Кнопка Plus
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,"+");
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,10);
     }
   if(m_type==4) // Кнопка Minus
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,"-");
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,13);
     }
   if(m_type==5) // Кнопка PageUp
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,CharToString(PAGE_UP));
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Wingdings 3");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,8);
     }
   if(m_type==6) // Кнопка PageDown
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,CharToString(PAGE_DOWN));
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Wingdings 3");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,8);
     }
   if(m_type>6) // Кнопка пустая
     {
      ObjectSetString(parent.chartID,name,OBJPROP_TEXT,"");
      ObjectSetString(parent.chartID,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(parent.chartID,name,OBJPROP_FONTSIZE,13);
     }
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+
