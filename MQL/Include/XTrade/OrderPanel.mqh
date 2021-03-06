//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <XTrade\ClassRow.mqh>
#include <XTrade\ITradeService.mqh>
#include <XTrade\TradeMethods.mqh>
#include <XTrade\TradePanel.mqh>

class TradePanel;
//+------------------------------------------------------------------+
//| класс OrderPanel  	                                             |
//+------------------------------------------------------------------+
class OrderPanel : public PanelBase
{
protected:
   TradePanel*       panel;
   Order*            order;   
   
   string TrailStrings[];   
   string RoleStrings[];

public:

   //---
   CRowType1         strOrder;       
   CRowType3         strRole;       
   CRowType3         strTrail;      
   CRowType2         strLotChange;     
   CRowType5         strProfit;
   CRowType2         strExpiration;         
   CRowType5         strApply;
   CRowType5         strDelete;

   OrderPanel(Order* ord, TradePanel* parent)
       :PanelBase(parent.chartID, parent.subWin)
       ,strOrder(GetPointer(this))
       ,strRole(GetPointer(this))
       ,strTrail(GetPointer(this))
       ,strLotChange(GetPointer(this))
       ,strProfit(GetPointer(this))
       ,strExpiration(GetPointer(this))
       ,strApply(GetPointer(this))
       ,strDelete(GetPointer(this))
   {
      panel =  parent;
      order = ord;
   }
   
   void ~OrderPanel() 
   {
   }

   void              Init();           // метод запуска главного модуля
   virtual void      OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   void              Draw();
   void              ClosePanel();
   void              Apply();
   void              CloseOrder();   
};

void OrderPanel::Init()
{
   w_corner = panel.w_corner;
   Property.H = panel.Property.H;
   
   w_xdelta = panel.w_xdelta + panel.w_bsize + 4;
   w_ydelta = panel.w_ydelta;

   if (GET(PanelSize) == PanelNormal)
   {
      w_bsize = 600;
      Property.H = 28;
      SetWin(w_xdelta, w_ydelta, w_bsize, CORNER_LEFT_UPPER);
   } else if (GET(PanelSize) == PanelSmall)
            {
               w_bsize = 300;
               SetWin(w_xdelta, w_ydelta, w_bsize, CORNER_LEFT_UPPER);
            }
            
   EnumArrayStrings<ENUM_TRAILING>(TrailStrings, TRAILS_COUNT);
   EnumArrayStrings<ENUM_ORDERROLE>(RoleStrings, ROLES_COUNT);

   strOrder.Property=Property;       
   strRole.Property=Property;       
   strTrail.Property=Property;      
   strLotChange.Property=Property;     
   strProfit.Property=Property;
   strExpiration.Property = Property;         
   strApply.Property=Property;
   strDelete.Property = Property;
   
   if (order != NULL)
   {
      strRole.Edit.SetText(EnumToString(order.Role()));
      strTrail.Edit.SetText(EnumToString(order.TrailingType));
      strLotChange.Edit.SetText(DoubleToString(order.lots, 2));      
      strExpiration.Edit.SetText(IntegerToString(order.RemainedHours()));
   }
}

//+------------------------------------------------------------------+
//| Метод Draw                                            
//+------------------------------------------------------------------+
void OrderPanel::Draw()
{   
   if (!bForceRedraw)
   {
      if (!AllowRedrawByEvenMinutesTimer(Symbol(),(ENUM_TIMEFRAMES) GET(RefreshTimeFrame)))
         return;
   }
   bForceRedraw = false;

   int X,Y,B;
   X=w_xpos;
   Y=w_ypos;
   B=w_bsize;
   
   strOrder.Property = Property;
   strRole.Property=Property;       
   strTrail.Property=Property;      
   strLotChange.Property=Property;     
   strProfit.Property=Property;
   strExpiration.Property = Property;         
   strApply.Property=Property;
   strDelete.Property=Property;

   if (order != NULL)
   {
      strOrder.Draw("OrderProp0", X, Y, B, 0, StringFormat("#%d %s", order.Id(), order.signalName));
      Y=Y+Property.H+DELTA; 
      strRole.Draw("RoleProp0", X, Y, B, 120, "Role");
      Y=Y+Property.H+DELTA;           
      strTrail.Draw("TrailProp0", X, Y, B, 120, "Trailing");
      Y=Y+Property.H+DELTA;
      strLotChange.Draw("LotChange0", X, Y, B, 120, "Lots");
      Y=Y+Property.H+DELTA;
      string profitString = StringFormat("%g DistancePt(%d)", DoubleToString(order.Profit(), Digits()), order.PriceDistanceInPoint());
      strProfit.Draw("Profit0", X, Y, B, 100, "Profit", profitString);
      Y=Y+Property.H+DELTA;
   } else {
      strOrder.Draw("OrderProp0", X, Y, B, 0, "Orders Properties");
      Y=Y+Property.H+DELTA;
   }
   
   strExpiration.Draw("ExpirationHours0", X, Y, B, 100, "Expiration(Hrs)");
   Y=Y+Property.H+DELTA;
   strApply.Draw("Apply0", X, Y, B, 100, "", "Apply");
   Y=Y+Property.H+DELTA;
   strDelete.Draw("Delete0", X, Y, B, 100, "", "Delete");
       
   ChartRedraw(chartID);
   on_event=true;   
}


void OrderPanel::ClosePanel()
{
   strOrder.Delete();
   strRole.Delete();
   strTrail.Delete();
   strLotChange.Delete();
   strProfit.Delete();
   strExpiration.Delete();
   strApply.Delete();
   strDelete.Delete();
   panel.SetForceRedraw();
   panel.Draw();
   panel.orderPanel = NULL;
   delete &this;
}

void OrderPanel::Apply(void)
{
   if (order != NULL)
   {
      string expirationText = strExpiration.Edit.GetText();
      int expirationHours = (int)StringToInteger(expirationText);
      if (expirationHours > 0)
      {
         order.expiration = TimeCurrent() + expirationHours * 60 * 60;
      }   
      string trail = strTrail.Edit.GetText();
      order.TrailingType = EnumValueFromString<ENUM_TRAILING>(TrailStrings, trail, order.TrailingType);
      
      string role = strRole.Edit.GetText();
      order.SetRole(EnumValueFromString<ENUM_ORDERROLE>(RoleStrings, role, order.Role()));
      
      double newLot = NormalizeDouble(StringToDouble(strLotChange.Edit.GetText()), 2);
      if (order.lots == 0)
      {
         if (order.Select())
         {
             order.lots = Utils.OrderLots();
         }
      }
      if (newLot == 0.0)
      {
          newLot = order.lots;
      }
      
      if ((MathAbs(order.lots - newLot) > 0.0001) && (newLot > 0))
      {
          Utils.Trade().CloseOrderPartially(order, newLot);
      }
      
      Utils.Trade().SaveOrders();
   }

   ClosePanel();
}

void OrderPanel::CloseOrder()
{
   if (order != NULL)
   {
      order.MarkToClose();
      order = NULL;
      Utils.Trade().SaveOrders();
      ClosePanel();
   }
}

void OrderPanel::OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(on_event)
     {         
      //--- трансляция событий OnChartEvent
         strOrder.OnEvent(id,lparam,dparam,sparam);
         strRole.OnEvent(id,lparam,dparam,sparam);
         strTrail.OnEvent(id,lparam,dparam,sparam);
         strLotChange.OnEvent(id,lparam,dparam,sparam);
         strProfit.OnEvent(id,lparam,dparam,sparam);
         strExpiration.OnEvent(id,lparam,dparam,sparam);
         strApply.OnEvent(id,lparam,dparam,sparam);
         strDelete.OnEvent(id,lparam,dparam,sparam);
        
        if((ENUM_CHART_EVENT)id==CHARTEVENT_OBJECT_CLICK)
        {
            //--- редактирование переменных [NEW3] : кнопка Plus STR3
            if( StringFind(sparam,".Button3",0)>0)
            {
               if (StringFind(sparam, strTrail.name) >= 0)
               {
                  string text = strTrail.Edit.GetText();
                  ENUM_TRAILING tr = EnumValueFromString<ENUM_TRAILING>(TrailStrings, text, order.TrailingType);
                  int i = (int)tr;
                  i++;
                  if (i < TRAILS_COUNT)
                     tr = (ENUM_TRAILING)i;
                  else 
                     tr = (ENUM_TRAILING)0;
                  strTrail.Edit.SetText(EnumToString(tr));   
                  SetForceRedraw();
                  Draw();                  
               }
                
               if (StringFind(sparam, strRole.name) >= 0)
               {
                  string text = strRole.Edit.GetText();
                  ENUM_ORDERROLE rol = EnumValueFromString<ENUM_ORDERROLE>(RoleStrings, text, order.Role());
                  int i = (int)rol;
                  i++;
                  if (i < ROLES_COUNT)
                     rol = (ENUM_ORDERROLE)i;
                  else 
                     rol = (ENUM_ORDERROLE)0;
                  strRole.Edit.SetText(EnumToString(rol));   
                  SetForceRedraw();
                  Draw();
               }
            }
            
            //--- редактирование переменных [NEW3] : кнопка Minus STR3
            if (StringFind(sparam,".Button4",0)>0)
            {
               if (StringFind(sparam, strTrail.name) >= 0)
               {
                  string text = strTrail.Edit.GetText();
                  ENUM_TRAILING tr = EnumValueFromString<ENUM_TRAILING>(TrailStrings, text, order.TrailingType);
                  int i = (int)tr;
                  i--;
                  if (i >= 0)
                     tr = (ENUM_TRAILING)i;
                  else 
                     tr = (ENUM_TRAILING)(TRAILS_COUNT - 1);
                  strTrail.Edit.SetText(EnumToString(tr));   
                  SetForceRedraw();
                  Draw();
               }
                
               if (StringFind(sparam, strRole.name) >= 0)
               {
                  string text = strRole.Edit.GetText();
                  ENUM_ORDERROLE rol = EnumValueFromString<ENUM_ORDERROLE>(RoleStrings, text, order.Role());
                  int i = (int)rol;
                  i--;
                  if (i >= 0)
                     rol = (ENUM_ORDERROLE)i;
                  else 
                     rol = (ENUM_ORDERROLE)(ROLES_COUNT - 1);
                  strRole.Edit.SetText(EnumToString(rol));   
                  SetForceRedraw();
                  Draw();
               }
            }
        
            if (StringFind(sparam, strApply.name) >= 0)
            {
               Apply();
               ChartRedraw(chartID);
               return;
            }
               
            if ((StringFind(sparam, strOrder.name) >= 0) &&
                 (StringFind(sparam,".Button1",0)>0))
            {
                ClosePanel();
                return;
            }
            
            if (StringFind(sparam, strDelete.name) >= 0)
            {
               CloseOrder();
               ChartRedraw(chartID);
               return;
            }

        }
     }
}

