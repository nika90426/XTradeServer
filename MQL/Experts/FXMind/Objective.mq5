//+------------------------------------------------------------------+
//|  Expert Adviser Object                             Objective.mq4 |
//|                                 Copyright 2013, Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"

#property strict

#define THRIFT 1

#include <FXMind\FXMindExpert.mqh>

FXMindExpert* expert = NULL;

void OnChartEvent(const int id,         // Event identifier  
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
{
   if (expert != NULL)
      expert.OnEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| expert main function                                            |
//+------------------------------------------------------------------+
void OnTick()
{  	
   if (expert != NULL)
   {
      expert.ProcessOrders();
      expert.Draw();
   }
}

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   string comment = "Objective";
#ifdef  __MQL4__
   if (IsTesting())
      comment = "Objective Debug";
#endif   

#ifdef  __MQL5__
   if ((bool)MQLInfoInteger(MQL_TESTER))
      comment = "Objective Debug";
#endif   
   Utils = CreateUtils((short)ThriftPORT, comment);  

   if (CheckPointer(Utils)==POINTER_INVALID)
   {
      Print("FAILED TO CREATE IUtils!!!");
      return INIT_FAILED;
   }
   //IFXMindService* res = Utils.Service();

   expert = new FXMindExpert();
   return expert.Init();
}

#ifdef  __MQL5__

void OnTrade()
{
    if (expert != NULL)
    {
       expert.UpdateOrders();
    }
}

#endif 

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{   
    if (expert != NULL)
    {
       expert.DeInit(reason);
       DELETE_PTR(expert);
    }
}

double OnTester()
{
   double resultLoss = TesterStatistics(STAT_LOSSTRADES_AVGCON);
   //double resultLoss = TesterStatistics(STAT_MAX_LOSSTRADE);
   double profitFactor = resultLoss;
   if (resultLoss != 0)
   // double resultLoss = TesterStatistics(STAT_EQUITYMIN);
   profitFactor = TesterStatistics(STAT_PROFIT_FACTOR)/resultLoss;
   return profitFactor;
}
