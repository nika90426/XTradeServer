//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#define  DELTA   1     // зазор между элементами по умолчанию
#include <XTrade\ClassUnit.mqh>
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Базовый класс СТРОКА  CRow                                       |
//+------------------------------------------------------------------+
class CRow
  {
protected:
   bool              on_event;      // флаг обработки событий
   PanelBase*        parent;
public:
   string            name;          // имя строки
   WinCell           Property;      // свойства строки
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRow(PanelBase* parent);
   virtual void     ~CRow()
   {
      Delete();
   }

   virtual     // Метод: нарисовать строку
   //void              Draw(string m_name,
   //                       int m_xdelta,
   //                       int m_ydelta,
   //                       int m_bsize);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
                             
   virtual void Delete() 
   {
       ObjectDelete( parent.chartID, name);
   }                          
};
//+------------------------------------------------------------------+
//| Конструктор класса CRow                                          |
//+------------------------------------------------------------------+
void CRow::CRow(PanelBase* p)
  :Property(p)
{
   parent = p;
   on_event=false;   // запрещаем обработку событий
}
//+------------------------------------------------------------------+
//| Метод Draw класса CRow                                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRow                 |
//+------------------------------------------------------------------+
void CRow::OnEvent(const int id,
                   const long &lparam,
                   const double &dparam,
                   const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      //---
     }
  }
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс СТРОКА тип 1:  CRowType1                                   |
//+------------------------------------------------------------------+
class CRowType1:public CRow
  {
public:
   CCellText         Text;
   CCellButtonType   Hide,Close;
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRowType1(PanelBase* p);
   virtual     // Метод: нарисовать строку
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          int m_type,
                          string m_text);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   virtual void Delete() 
   {
       Text.Delete();
       Hide.Delete();
       Close.Delete();
       ObjectDelete( parent.chartID, name);
   }                          
  };
//+------------------------------------------------------------------+
//| Конструктор класса CRowType1                                     |
//+------------------------------------------------------------------+
void CRowType1::CRowType1(PanelBase* p)
  :CRow(p),Text(p),Hide(p), Close(p)
{
}
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType1            |
//+------------------------------------------------------------------+
void CRowType1::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
{
   if(on_event) // обработка событий разрешена
     {
      Text.OnEvent(id,lparam,dparam,sparam);
      Hide.OnEvent(id,lparam,dparam,sparam);
      Close.OnEvent(id,lparam,dparam,sparam);
     }
}
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType1                                      |
//+------------------------------------------------------------------+
void CRowType1::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     int m_type,
                     string m_text)
  {
   int      X,B;
   Text.Property=Property;
   Hide.Property=Property;
   Close.Property=Property;
//--- тип 0: m_type=0
   if(m_type<=0)
     {
      name=m_name+".RowType1(0)";
      B=m_bsize-2*(Property.H+DELTA);
      Text.SetText(m_text);
      Text.Draw(name,m_xdelta,m_ydelta,B);
      //---
      X=m_xdelta+Property.Corn*(B+DELTA);
      Hide.Draw(name,X,m_ydelta,0);
      //---
      X=X+Property.Corn*(Property.H+DELTA);
      Close.Draw(name,X,m_ydelta,1);
     }
//--- тип 1: m_type=1
   if(m_type==1)
     {
      name=m_name+".RowType1(1)";
      B=m_bsize-(Property.H+DELTA);
      Text.SetText(m_text);
      Text.Draw(name,m_xdelta,m_ydelta,B);
      //---
      X=m_xdelta+Property.Corn*(B+DELTA);
      Close.Draw(name,X,m_ydelta,1);
     }
//--- тип 2: m_type=2
   if(m_type==2)
     {
      name=m_name+".RowType1(2)";
      B=m_bsize-(Property.H+DELTA);
      Text.SetText(m_text);
      Text.Draw(name,m_xdelta,m_ydelta,B);
      //---
      X=m_xdelta+Property.Corn*(B+DELTA);
      Hide.Draw(name,X,m_ydelta,0);
     }
//--- тип 3: m_type=3
   if(m_type>=3)
     {
      name=m_name+".RowType1(3)";
      B=m_bsize;
      Text.SetText(m_text);
      Text.Draw(name,m_xdelta,m_ydelta,B);
     }
//---
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс СТРОКА тип 2:  CRowType2                                   |
//+------------------------------------------------------------------+
class CRowType2:public CRow
  {
public:
   CCellText         Text;
   CCellEdit         Edit;
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRowType2(PanelBase* p);
   virtual     // Метод: нарисовать строку
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          int m_tsize,
                          string m_text);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   virtual void Delete() 
   {
       Text.Delete();
       Edit.Delete();
       ObjectDelete(parent.chartID, name);
   }                          

  };
//+------------------------------------------------------------------+
//| Конструктор класса CRowType2                                     |
//+------------------------------------------------------------------+
void CRowType2::CRowType2(PanelBase* p)
  :CRow(p),Text(p),Edit(p)
{
}
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType2            |
//+------------------------------------------------------------------+
void CRowType2::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      Text.OnEvent(id,lparam,dparam,sparam);
      Edit.OnEvent(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType2                                      |
//+------------------------------------------------------------------+
void CRowType2::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     int m_tsize,
                     string m_text)
  {
   int      X,B;
   Text.Property=Property;
   Edit.Property=Property;
   name=m_name+".RowType2";
   Text.SetText(m_text);
   Text.Draw(name,m_xdelta,m_ydelta,m_tsize);
//---
   B=m_bsize-m_tsize-DELTA;
   X=m_xdelta+Property.Corn*(m_tsize+DELTA);
   //Edit.SetText(m_edit);
   Edit.Draw(name,X,m_ydelta,B,false);
//---
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Класс СТРОКА тип 3:  CRowType3                                   |
//+------------------------------------------------------------------+
class CRowType3:public CRow
  {
public:
   CCellText         Text;
   CCellEdit         Edit;
   CCellButtonType   Plus,Minus;
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRowType3(PanelBase* p);
   virtual     // Метод: нарисовать строку
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          int m_tsize,
                          string m_text);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   virtual void Delete() 
   {
       Text.Delete();
       Edit.Delete();
       Plus.Delete();
       Minus.Delete();
       ObjectDelete(parent.chartID, name);
   }                          
                          
  };
//+------------------------------------------------------------------+
//| Конструктор класса CRowType3                                     |
//+------------------------------------------------------------------+
void CRowType3::CRowType3(PanelBase* p)
  :CRow(p),Text(p),Edit(p), Plus(p), Minus(p)
{
}
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType3            |
//+------------------------------------------------------------------+
void CRowType3::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      Text.OnEvent(id,lparam,dparam,sparam);
      Edit.OnEvent(id,lparam,dparam,sparam);
      Plus.OnEvent(id,lparam,dparam,sparam);
      Minus.OnEvent(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType3                                      |
//+------------------------------------------------------------------+
void CRowType3::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     int m_tsize,
                     string m_text)
  {
   int      X,B;
   Text.Property=Property;
   Edit.Property=Property;
   Plus.Property=Property;
   Minus.Property=Property;
   name=m_name+".RowType3";
   Text.SetText(m_text);
   Text.Draw(name,m_xdelta,m_ydelta,m_tsize);
//---
   B=m_bsize-(m_tsize+DELTA)-2*(Property.H+DELTA);
   X=m_xdelta+Property.Corn*(m_tsize+DELTA);
   Edit.Draw(name,X,m_ydelta,B,true);
//---
   X=X+Property.Corn*(B+DELTA);
   Plus.Draw(name,X,m_ydelta,3);
//---
   X=X+Property.Corn*(Property.H+DELTA);
   Minus.Draw(name,X,m_ydelta,4);
//---
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+

//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс СТРОКА тип 4:  CRowType4                                   |
//+------------------------------------------------------------------+
class CRowType4:public CRow
  {
public:
   CCellText         Text;
   CCellEdit         Edit;
   CCellButtonType   Plus,Minus,Up,Down;
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRowType4(PanelBase* p);
   virtual     // Метод: нарисовать строку
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          int m_tsize,
                          string m_text,
                          string m_edit);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
                             
   virtual void Delete() 
   {
       Text.Delete();
       Edit.Delete();
       Plus.Delete();
       Minus.Delete();
       Up.Delete();
       Down.Delete();
       ObjectDelete(parent.chartID, name);
   }                          
                             
  };
//+------------------------------------------------------------------+
//| Конструктор класса CRowType4                                     |
//+------------------------------------------------------------------+
void CRowType4::CRowType4(PanelBase* p)
  :CRow(p),Text(p),Edit(p), Plus(p), Minus(p), Up(p), Down(p)
{
}
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType4            |
//+------------------------------------------------------------------+
void CRowType4::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      Text.OnEvent(id,lparam,dparam,sparam);
      Edit.OnEvent(id,lparam,dparam,sparam);
      Plus.OnEvent(id,lparam,dparam,sparam);
      Minus.OnEvent(id,lparam,dparam,sparam);
      Up.OnEvent(id,lparam,dparam,sparam);
      Down.OnEvent(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType4                                      |
//+------------------------------------------------------------------+
void CRowType4::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     int m_tsize,
                     string m_text,
                     string m_edit)
  {
   int      X,B;
   Text.Property=Property;
   Edit.Property=Property;
   Plus.Property=Property;
   Minus.Property=Property;
   Up.Property=Property;
   Down.Property=Property;
   name=m_name+".RowType4";
   Text.SetText(m_text);
   Text.Draw(name,m_xdelta,m_ydelta,m_tsize);
//---
   B=m_bsize-(m_tsize+DELTA)-4*(Property.H+DELTA);
   X=m_xdelta+Property.Corn*(m_tsize+DELTA);
   Edit.SetText(m_edit);
   Edit.Draw(name,X,m_ydelta,B,true);
//---
   X=X+Property.Corn*(B+DELTA);
   Plus.Draw(name,X,m_ydelta,3);
//---
   X=X+Property.Corn*(Property.H+DELTA);
   Minus.Draw(name,X,m_ydelta,4);
//---
   X=X+Property.Corn*(Property.H+DELTA);
   Up.Draw(name,X,m_ydelta,5);
//---
   X=X+Property.Corn*(Property.H+DELTA);
   Down.Draw(name,X,m_ydelta,6);
//---
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс СТРОКА тип 5:  CRowType5                                   |
//+------------------------------------------------------------------+
class CRowType5:public CRow
  {
public:
   CCellText         Text;
   CCellButton       Button;
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRowType5(PanelBase* p);
   virtual     // Метод: нарисовать строку
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          int m_csize,
                          string m_text,
                          string m_button);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
                             
   virtual void Delete() 
   {
       Text.Delete();
       Button.Delete();
       ObjectDelete(parent.chartID, name);
   }                          
                             
  };
  
//+------------------------------------------------------------------+
//| Конструктор класса CRowType5                                     |
//+------------------------------------------------------------------+
void CRowType5::CRowType5(PanelBase* p)
  :CRow(p),Text(p),Button(p)
  {
  }
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType5            |
//+------------------------------------------------------------------+
void CRowType5::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      Text.OnEvent(id,lparam,dparam,sparam);
      Button.OnEvent(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType5                                      |
//+------------------------------------------------------------------+
void CRowType5::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     int m_csize,
                     string m_text,
                     string m_button)
  {
   int      X,B;
   Text.Property=Property;
   Button.Property=Property;
   name=m_name+".RowType5";
   Text.SetText(m_text);
   Text.Draw(name,m_xdelta,m_ydelta,m_csize);
//---
   B=m_bsize-m_csize-DELTA;
   X=m_xdelta+Property.Corn*(m_csize+DELTA);
   Button.Draw(name,X,m_ydelta,B,m_button);
//---
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс СТРОКА тип 6:  CRowType6                                   |
//+------------------------------------------------------------------+
class CRowType6:public CRow
  {
public:
   CCellButton       Button;
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRowType6(PanelBase* p);
   virtual     // Метод: нарисовать строку
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          int m_b1size,
                          int m_b2size,
                          string m_button1,
                          string m_button2,
                          string m_button3);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   virtual void Delete() 
   {
       Button.Delete();
       ObjectDelete(parent.chartID, name);
   }                          
                             
  };
//+------------------------------------------------------------------+
//| Конструктор класса CRowType6                                     |
//+------------------------------------------------------------------+
void CRowType6::CRowType6(PanelBase* p)
  :CRow(p),Button(p)
{
}
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType6            |
//+------------------------------------------------------------------+
void CRowType6::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      Button.OnEvent(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType6                                      |
//+------------------------------------------------------------------+
void CRowType6::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     int m_b1size,
                     int m_b2size,
                     string m_button1,
                     string m_button2,
                     string m_button3
                     )
  {
   int      X,B;
   Button.Property=Property;
//---
   name=m_name+".RowType6(1)";
   B=m_b1size;
   X=m_xdelta;
   Button.Draw(name,X,m_ydelta,B,m_button1);
//---
   name=m_name+".RowType6(2)";
   B=m_b2size;
   X=X+Property.Corn*(m_b1size+DELTA);
   Button.Draw(name,X,m_ydelta,B,m_button2);
//---
   name=m_name+".RowType6(3)";
   B=m_bsize-(m_b1size+DELTA)-(m_b2size+DELTA);
   X=X+Property.Corn*(m_b2size+DELTA);
   Button.Draw(name,X,m_ydelta,B,m_button3);
//+------------------------------------------------------------------+
   on_event=true;   // разрешаем обработку событий
  }
//+------------------------------------------------------------------+


class CRowTypeLabel:public CRow
{
   public:
   CCellText         Text;
   void              CRowTypeLabel(PanelBase* p);
   virtual     
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
       Text.Delete();
       ObjectDelete(parent.chartID, name);
   }                          

};
//+------------------------------------------------------------------+
//| Конструктор класса CRowType2                                     |
//+------------------------------------------------------------------+
void CRowTypeLabel::CRowTypeLabel(PanelBase* p)
  :CRow(p),Text(p)
{
}
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType2            |
//+------------------------------------------------------------------+
void CRowTypeLabel::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
{
if(on_event) // обработка событий разрешена
  {
   Text.OnEvent(id,lparam,dparam,sparam);
  }
}
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType2                                      |
//+------------------------------------------------------------------+
void CRowTypeLabel::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize)
{
   Text.Property=Property;
   name=m_name+".RowType2";
   //Text.SetText(m_text);   
   Text.Draw(name,m_xdelta,m_ydelta,m_bsize);
   on_event=true;   // разрешаем обработку событий
}


//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Класс СТРОКА тип 3:  CRowTypeOrder                                   |
//+------------------------------------------------------------------+
class CRowTypeOrder : public CRow
{
public:
   CCellText         Text;
   //CCellEdit         Edit;
   CCellButtonType   Plus, Minus;
   //+---------------------------------------------------------------+
   // Конструктор класса
   void              CRowTypeOrder(PanelBase* p);
   virtual     // Метод: нарисовать строку
   void              Draw(string m_name,
                          int m_xdelta,
                          int m_ydelta,
                          int m_bsize,
                          //int m_tsize,
                          string m_text);
   virtual     // Метод обработки события OnChartEvent
   void              OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   virtual void Delete() 
   {
       Text.Delete();
       //Edit.Delete();
       Plus.Delete();
       Minus.Delete();
       ObjectDelete(parent.chartID, name);
   }                          
                          
};
//+------------------------------------------------------------------+
//| Конструктор класса CRowType3                                     |
//+------------------------------------------------------------------+
void CRowTypeOrder::CRowTypeOrder(PanelBase* p)
  :CRow(p),Text(p),Plus(p), Minus(p)
{
}
//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса CRowType3            |
//+------------------------------------------------------------------+
void CRowTypeOrder::OnEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
  {
   if(on_event) // обработка событий разрешена
     {
      Text.OnEvent(id,lparam,dparam,sparam);
      //Edit.OnEvent(id,lparam,dparam,sparam);
      Plus.OnEvent(id,lparam,dparam,sparam);
      Minus.OnEvent(id,lparam,dparam,sparam);
     }
  }
//+------------------------------------------------------------------+
//| Метод Draw класса CRowType3                                      |
//+------------------------------------------------------------------+
void CRowTypeOrder::Draw(string m_name,
                     int m_xdelta,
                     int m_ydelta,
                     int m_bsize,
                     //int m_tsize,
                     string m_text)
  {
   int      X,B;
   Text.Property=Property;
   //Edit.Property=Property;
   Plus.Property=Property;
   Minus.Property=Property;
   name=m_name+".RowType3";
   Text.SetText(m_text);
   Text.Draw(name,m_xdelta,m_ydelta,m_bsize);
//---
   B=m_bsize-2*(Property.H+DELTA);
   //X=m_xdelta+Property.Corn*(m_tsize+DELTA);
   //Edit.Draw(name,X,m_ydelta,B,true);
//---
   X=m_xdelta+Property.Corn*(B+DELTA);
   Plus.Draw(name,X,m_ydelta,3);
//---
   X=X+Property.Corn*(Property.H+DELTA);
   Minus.Draw(name,X,m_ydelta,4);
//---
   on_event=true;   // разрешаем обработку событий
  }
